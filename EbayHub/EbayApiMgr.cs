using eBay.Service.Call;
using eBay.Service.Core.Sdk;
using eBay.Service.Core.Soap;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    enum EbayApiRequestMode
    { 
        AuthUser,
        Developer
    }

    enum ResultSortOrder
    {
        Ascending,
        Descending
    }
    
    class EbayApiMgr
    {
        private const string ApiServerUrl = "https://api.ebay.com/wsapi"; // Production server
        private const string UserAuthTokenFileName = "EbayUserAuthToken.txt"; // Relative to the app's root dir

        private HiddenForm msgLoopForm;

        private ApiContext apiCtx;
        private string userAuthToken;

        private GetOrdersCall getOrdersCall;

        private bool unableState = false;
        
        public EbayApiMgr(HiddenForm messageLoopForm)
        {
            msgLoopForm = messageLoopForm;
        }

        public void Init()
        {
            SetupAuthorization();
            SetupApiContext();
        }

        private void SetupAuthorization()
        {
            if (!File.Exists(UserAuthTokenFileName))
            {
                unableState = true;
                msgLoopForm.SendComMessage(QnProcessComProtocol.MsgCode_EbayAuthTokenError);
                return;
            }

            userAuthToken = File.ReadAllText(UserAuthTokenFileName);
        }

        private void SetupApiContext()
        {
            apiCtx = new ApiContext();

            apiCtx.SoapApiServerUrl = ApiServerUrl;
            apiCtx.Site = SiteCodeType.US;

            ApiCredential creds = new ApiCredential();
            creds.eBayToken = userAuthToken;
            apiCtx.ApiCredential = creds;
        }

        private void SetupGetOrdersCallCommon(ref GetOrdersCall getOrdersCall)
        {
            getOrdersCall.OrderRole = TradingRoleCodeType.Seller;
            getOrdersCall.OrderStatus = OrderStatusCodeType.All;
            getOrdersCall.SortingOrder = SortOrderCodeType.Descending;
        }

        public List<OrderType> GetOrders(DateTime createTimeFrom, DateTime createTimeTo, ResultSortOrder resultSetSortOrder)
        {
            if (unableState)
                return null;
            
            getOrdersCall = new GetOrdersCall(apiCtx);
            SetupGetOrdersCallCommon(ref getOrdersCall);

            getOrdersCall.CreateTimeFrom = createTimeFrom;
            getOrdersCall.CreateTimeTo = createTimeTo;
            getOrdersCall.Pagination = new PaginationType();

            var resultList = new List<OrderType>();
            int currentPageNumber = 0;
            int totalPagesNumber = 1; // Default
            
            while (true)
            {
                currentPageNumber++;

                getOrdersCall.Pagination.PageNumber = currentPageNumber;

                getOrdersCall.Execute();

                if (currentPageNumber == 1 && getOrdersCall.OrderList.Count <= 0)
                    return null;

                // Collect the data
                foreach (OrderType orderInfo in getOrdersCall.OrderList)
                {
                    resultList.Add(orderInfo);
                }

                if (currentPageNumber == 1 && getOrdersCall.PaginationResult.TotalNumberOfPages > 1)
                {
                    totalPagesNumber = getOrdersCall.PaginationResult.TotalNumberOfPages;
                }

                if (currentPageNumber == totalPagesNumber)
                    break;
            }

            resultList = resultSetSortOrder == ResultSortOrder.Descending ? 
                resultList.OrderByDescending(x => x.CreatedTime).ToList() :
                resultList.OrderBy(x => x.CreatedTime).ToList();

            return resultList;
        }
    }
}
