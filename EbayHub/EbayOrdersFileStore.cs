using eBay.Service.Core.Sdk;
using eBay.Service.Core.Soap;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Linq;

namespace Quantum.EbayHub
{
    class EbayOrdersFileStore
    {
        const string StoreFormatVersion = "1.1";
        const string StoreFileName = "ebay-orders.xml";
        const string PhoneCountryCodesFileName = "PhoneCountryCodes.json";
        const int FullRequestOrdersBackInDays = 30; // Was: 60
        const int StoreOrdersBackInDaysMax = 90; // 90
        const int StoreOrdersMaxRecords = 1300;
        const string dateStrFormat = "o";

        #region Names

        const string XmlStoreElementName_Root = "QuantumEbayOrdersStore";
        const string XmlStoreElementName_MetaInfo = "MetaInfo";
        const string XmlStoreElementName_StoreFormatVersion = "FormatVer";
        const string XmlStoreElementName_LastCheckTime = "LastCheckTime";
        const string XmlStoreElementName_Store = "Store";
        const string XmlStoreElementName_Order = "Order";
        const string XmlStoreElementName_OrderID = "OrderID";
        const string XmlStoreElementName_OrderStatus = "OrderStatus";
        const string XmlStoreElementName_BuyerUserID = "BuyerUserID";
        const string XmlStoreElementName_CreatedTime = "CreatedTime";
        const string XmlStoreElementName_ShippingAddress = "ShippingAddress";
        const string XmlStoreElementName_ClientName = "ClientName";
        const string XmlStoreElementName_CountryCode = "CountryCode";
        const string XmlStoreElementName_CountryName = "CountryName";
        const string XmlStoreElementName_City = "City";
        const string XmlStoreElementName_Region = "Region";
        const string XmlStoreElementName_Street1 = "Street1";
        const string XmlStoreElementName_Street2 = "Street2";
        const string XmlStoreElementName_PostCode = "PostCode";
        const string XmlStoreElementName_Phone = "Phone";
        const string XmlStoreElementName_PhoneCountryCode = "PhoneCountryCode";
        const string XmlStoreElementName_TransactionItems = "TransactionItems";
        const string XmlStoreElementName_Item = "Item";
        const string XmlStoreElementName_ItemID = "ItemID";
        const string XmlStoreElementName_ItemSKU = "SKU";
        const string XmlStoreElementName_ItemTitle = "Title";
        const string XmlStoreElementName_QuantityPurchased = "QuantityPurchased";

        const string XmlStoreAttributeName_Value = "Val";

        const string JsonStorePropName_CountryName = "countryName";
        const string JsonStorePropName_CountryCode = "countryCode";
        const string JsonStorePropName_PhoneCode = "phoneCode";

        #endregion

        private HiddenForm msgLoopForm;
        private EbayApiMgr apiMgr;

        private string storeFilePath;
        private XDocument storeXmlDom;
        private XmlWriterSettings xmlWriterSettings;
        private XmlWriter xmlWriter;
        private Dictionary<string, PhoneCountryCode> phoneCodesBase;

        private XElement RootEl => storeXmlDom.Element(XmlStoreElementName_Root);

        private XElement MetaInfoEl => RootEl.Element(XmlStoreElementName_MetaInfo);

        private XElement StoreEl => RootEl.Element(XmlStoreElementName_Store);

        private int StoreOrdersCount => StoreEl.Elements(XmlStoreElementName_Order).Count();

        public EbayOrdersFileStore(HiddenForm messageLoopForm, EbayApiMgr ebayApiMgr)
        {
            msgLoopForm = messageLoopForm;
            apiMgr = ebayApiMgr;
        }

        public void Init()
        {
            storeFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), 
                "Quantum", "Local Store", StoreFileName);

            xmlWriterSettings = new XmlWriterSettings();
            xmlWriterSettings.Indent = true;
            xmlWriterSettings.IndentChars = ("\t");
            xmlWriterSettings.OmitXmlDeclaration = true;

            if (!File.Exists(storeFilePath))
            {
                CreateBlankStore();
            }
            else
            {
                var xmlFileContent = File.ReadAllText(storeFilePath);

                if (xmlFileContent.Length == 0)
                {
                    CreateBlankStore(); // It will rewrite even existing file with default one
                }

                else
                {
                    try
                    {
                        storeXmlDom = XDocument.Load(storeFilePath);
                    }
                    catch (Exception)
                    {
                        CreateBlankStore();
                    }
                }
            }

            // Phone country codes database
            if (!File.Exists(PhoneCountryCodesFileName))
            {
                msgLoopForm.SendComMessage(ProcessComProtocol.MsgCode_SysError);
            }
            else
            {
                JArray phoneCodesJsonBase;

                try
                {
                    phoneCodesJsonBase = JArray.Parse(File.ReadAllText(PhoneCountryCodesFileName));
                }
                catch (Exception)
                {
                    msgLoopForm.SendComMessage(ProcessComProtocol.MsgCode_SysError);
                    return;
                }
                
                phoneCodesBase = new Dictionary<string, PhoneCountryCode>(phoneCodesJsonBase.Count);
                PhoneCountryCode dbEntry;

                foreach (JObject jsonEntry in phoneCodesJsonBase)
                {
                    dbEntry = new PhoneCountryCode
                    {
                        CountryName = jsonEntry[JsonStorePropName_CountryName].Value<string>(),
                        CountryCode = jsonEntry[JsonStorePropName_CountryCode].Value<string>(),
                        PhoneCode = jsonEntry[JsonStorePropName_PhoneCode].Value<string>()
                    };

                    phoneCodesBase[dbEntry.CountryCode] = dbEntry;
                }
            }
        }

        public async Task CheckAsync(bool fullMandatory = false)
        {
            msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersCheckStarted);

            if (fullMandatory)
                ClearCache();
            else
                ReloadFile();

            DateTime lastSavedOrderCreatedTime = default;
            DateTime lastCheckTime = default;
            bool fullRequestNeeded = false;

            string lastCheckTimeValue = MetaInfoEl
                .Element(XmlStoreElementName_LastCheckTime)
                .Attribute(XmlStoreAttributeName_Value).Value;

            if (lastCheckTimeValue == string.Empty || StoreOrdersCount == 0)
                fullRequestNeeded = true;
            
            if (lastCheckTimeValue != string.Empty)
                lastCheckTime = ParseUtcDateTime(lastCheckTimeValue);

            if (StoreOrdersCount > 0)
            {
                lastSavedOrderCreatedTime = ParseUtcDateTime(
                    StoreEl.Elements(XmlStoreElementName_Order).First()
                        .Element(XmlStoreElementName_CreatedTime)
                        .Attribute(XmlStoreAttributeName_Value).Value
                );
            }

            List<OrderType> ordersRequestResult = null;
            Task apiRequestTask;
            
            Action getEbayOrdersFull = () => 
            {
                DateTime mtimeTo = DateTime.UtcNow;
                DateTime mtimeFrom = mtimeTo.AddDays(-FullRequestOrdersBackInDays);
                ordersRequestResult = apiMgr.GetOrders(mtimeFrom, mtimeTo, ResultSortOrder.Descending); // Recent first
            };

            Action getEbayOrdersUpdateOnly = () =>
            {
                DateTime mtimeFrom = lastCheckTime;
                DateTime mtimeTo = DateTime.UtcNow;
                ordersRequestResult = apiMgr.GetOrders(mtimeFrom, mtimeTo, ResultSortOrder.Ascending); // Recent at the end
            };

            if (fullRequestNeeded)
            {
                apiRequestTask = Task.Run(getEbayOrdersFull);
            }
            else
            {
                apiRequestTask = Task.Run(getEbayOrdersUpdateOnly);
            }

            try
            {
                await apiRequestTask;
            }
            catch (ApiException e)
            {
                msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersCheckError);
                return;
            }
            catch (Exception e)
            {
                msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersCheckError);
                return;
            }

            int newEntriesCount = 0;

            if (ordersRequestResult != null)
                newEntriesCount = ProcessOrdersRequestResult(ordersRequestResult, !fullRequestNeeded);

            // Save current successful check time
            MetaInfoEl
                .Element(XmlStoreElementName_LastCheckTime)
                .Attribute(XmlStoreAttributeName_Value).Value
                    = DateTime.UtcNow.ToString(dateStrFormat);

            CheckStoreOverflow();

            SaveFile();

            object msgData = new { newEntriesCount = newEntriesCount.ToString() };
            msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersCheckSuccess, msgData);
        }

        public void ReloadFile()
        {
            storeXmlDom = XDocument.Load(storeFilePath);
        }

        public void ClearCache()
        {
            DeleteFile();
            CreateBlankStore();
            msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersStoreUpdated);
            msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayOrdersCacheCleared);
        }

        private DateTime ParseUtcDateTime(string dateTimeString)
        {
            return DateTime.Parse(dateTimeString, null, System.Globalization.DateTimeStyles.RoundtripKind);
        }

        private void CheckStoreOverflow()
        {
            XElement lastOrderEntry;
            while (StoreOrdersCount > StoreOrdersMaxRecords)
            {
                lastOrderEntry = StoreEl.Elements(XmlStoreElementName_Order).Last();
                lastOrderEntry.Remove();
            }
        }

        private int ProcessOrdersRequestResult(List<OrderType> resultOrders, bool updateMode)
        {
            XElement orderEl;
            XElement orderIdEl;
            XElement orderStatusEl;
            XElement createdTimeEl;
            XElement buyerUserIdEl;
            XElement shippingAdrEl;
            XElement adrClientNameEl;
            XElement adrCountryCodeEl;
            XElement adrCountryNameEl;
            XElement adrRegionEl;
            XElement adrCityEl;
            XElement adrStreet1El;
            XElement adrStreet2El;
            XElement adrPostCodeEl;
            XElement adrPhoneEl;
            XElement adrPhoneCountryCodeEl;

            string phoneCountryCodeUsed;
            int selectedOrdersCount = 0;

            foreach (var ebayOrderEntry in resultOrders)
            {
                if (ebayOrderEntry.OrderStatus != OrderStatusCodeType.Completed)
                    continue;

                // Skip already stored orders
                var q = StoreEl.Elements(XmlStoreElementName_Order).Where(ord => 
                    ord.Elements(XmlStoreElementName_OrderID).Attributes(XmlStoreAttributeName_Value).FirstOrDefault().Value == ebayOrderEntry.OrderID
                        &&
                    ord.Elements(XmlStoreElementName_OrderStatus).Attributes(XmlStoreAttributeName_Value).FirstOrDefault().Value == OrderStatusCodeType.Completed.ToString()
                    );

                if (q.Count() > 0)
                    continue;

                orderEl = new XElement(XmlStoreElementName_Order);
                orderIdEl = new XElement(XmlStoreElementName_OrderID);
                orderStatusEl = new XElement(XmlStoreElementName_OrderStatus);
                createdTimeEl = new XElement(XmlStoreElementName_CreatedTime);
                buyerUserIdEl = new XElement(XmlStoreElementName_BuyerUserID);
                shippingAdrEl = new XElement(XmlStoreElementName_ShippingAddress);
                adrClientNameEl = new XElement(XmlStoreElementName_ClientName);
                adrCountryCodeEl = new XElement(XmlStoreElementName_CountryCode);
                adrCountryNameEl = new XElement(XmlStoreElementName_CountryName);
                adrRegionEl = new XElement(XmlStoreElementName_Region);
                adrCityEl = new XElement(XmlStoreElementName_City);
                adrStreet1El = new XElement(XmlStoreElementName_Street1);
                adrStreet2El = null;
                adrPostCodeEl = new XElement(XmlStoreElementName_PostCode);
                adrPhoneEl = new XElement(XmlStoreElementName_Phone);
                adrPhoneCountryCodeEl = null;

                orderStatusEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                orderStatusEl.Attribute(XmlStoreAttributeName_Value).Value = ebayOrderEntry.OrderStatus.ToString();

                orderIdEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                orderIdEl.Attribute(XmlStoreAttributeName_Value).Value = ebayOrderEntry.OrderID;

                createdTimeEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                createdTimeEl.Attribute(XmlStoreAttributeName_Value).Value = 
                    ebayOrderEntry.CreatedTime.ToString(dateStrFormat);

                buyerUserIdEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                buyerUserIdEl.Attribute(XmlStoreAttributeName_Value).Value = ebayOrderEntry.BuyerUserID;

                adrClientNameEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrClientNameEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.Name;

                adrCountryCodeEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrCountryCodeEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.Country.ToString();

                adrCountryNameEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrCountryNameEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.CountryName;

                adrRegionEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrRegionEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.StateOrProvince;

                adrCityEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrCityEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.CityName;

                adrStreet1El.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrStreet1El.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.Street1;

                if (ebayOrderEntry.ShippingAddress.Street2 != null && ebayOrderEntry.ShippingAddress.Street2 != string.Empty)
                {
                    adrStreet2El = new XElement(XmlStoreElementName_Street2);

                    adrStreet2El.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                    adrStreet2El.Attribute(XmlStoreAttributeName_Value).Value =
                        ebayOrderEntry.ShippingAddress.Street2;
                }

                adrPostCodeEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                adrPostCodeEl.Attribute(XmlStoreAttributeName_Value).Value =
                    ebayOrderEntry.ShippingAddress.PostalCode;

                if (ebayOrderEntry.ShippingAddress.PhoneCountryCodeSpecified)
                {
                    phoneCountryCodeUsed = ebayOrderEntry.ShippingAddress.PhoneCountryCode.ToString();

                    adrPhoneCountryCodeEl = new XElement(XmlStoreElementName_PhoneCountryCode);
                    adrPhoneCountryCodeEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));
                    adrPhoneCountryCodeEl.Attribute(XmlStoreAttributeName_Value).Value = phoneCountryCodeUsed;
                }
                else
                {
                    phoneCountryCodeUsed = ebayOrderEntry.ShippingAddress.Country.ToString();
                }

                adrPhoneEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));

                if (ebayOrderEntry.ShippingAddress.Phone != "Invalid Request" && phoneCodesBase.ContainsKey(phoneCountryCodeUsed))
                    adrPhoneEl.Attribute(XmlStoreAttributeName_Value).Value =
                        phoneCodesBase[phoneCountryCodeUsed].PhoneCode + " " + ebayOrderEntry.ShippingAddress.Phone;

                orderEl.Add(orderIdEl);
                orderEl.Add(orderStatusEl);
                orderEl.Add(createdTimeEl);
                orderEl.Add(buyerUserIdEl);
                orderEl.Add(shippingAdrEl);

                shippingAdrEl.Add(adrClientNameEl);
                shippingAdrEl.Add(adrCountryCodeEl);
                shippingAdrEl.Add(adrCountryNameEl);
                shippingAdrEl.Add(adrRegionEl);
                shippingAdrEl.Add(adrCityEl);
                shippingAdrEl.Add(adrStreet1El);

                if (adrStreet2El != null)
                    shippingAdrEl.Add(adrStreet2El);

                shippingAdrEl.Add(adrPostCodeEl);
                shippingAdrEl.Add(adrPhoneEl);

                if (adrPhoneCountryCodeEl != null)
                    shippingAdrEl.Add(adrPhoneCountryCodeEl);

                if (updateMode)
                    StoreEl.AddFirst(orderEl);
                else
                    StoreEl.Add(orderEl);

                selectedOrdersCount++;
            }

            return selectedOrdersCount;
        }

        private void CreateBlankStore(bool saveToFile = true)
        {
            storeXmlDom = new XDocument();

            var root = new XElement(XmlStoreElementName_Root);
            var metaInfoEl = new XElement(XmlStoreElementName_MetaInfo);
            var storeEl = new XElement(XmlStoreElementName_Store);

            var lastCheckTimeEl = new XElement(XmlStoreElementName_LastCheckTime);
            var formatVerEl = new XElement(XmlStoreElementName_StoreFormatVersion);

            formatVerEl.Add(new XAttribute(XmlStoreAttributeName_Value, StoreFormatVersion));
            lastCheckTimeEl.Add(new XAttribute(XmlStoreAttributeName_Value, ""));

            metaInfoEl.Add(formatVerEl);
            metaInfoEl.Add(lastCheckTimeEl);

            storeXmlDom.Add(root);
            root.Add(metaInfoEl);
            root.Add(storeEl);

            if (saveToFile)
                SaveFile();
        }

        private void SaveFile()
        {
            if (storeXmlDom == null)
                return;

            using (xmlWriter = XmlWriter.Create(storeFilePath, xmlWriterSettings))
            {
                storeXmlDom.Save(xmlWriter);
            }
        }

        private void DeleteFile()
        {
            if (File.Exists(storeFilePath))
                File.Delete(storeFilePath);
        }
    }

    class PhoneCountryCode
    {
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string PhoneCode { get; set; }
    }
}
