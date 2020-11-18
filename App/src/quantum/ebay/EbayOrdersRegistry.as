package quantum.ebay 
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import quantum.Main;
	import quantum.ebay.EbayAddress;
	import quantum.events.EbayHubEvent;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayOrdersRegistry 
	{
		private static const storeFileName:String = "ebay-orders.xml";
		
		private var main:Main;
		
		private var xmlDoc:XML;
		private var storeFile:File;
		private var fstream:FileStream;
		
		private var $events:EventDispatcher;
		
		private function get storeEl():XML
		{
			return xmlDoc == null ? null : xmlDoc.Store[0];
		}
		
		public function EbayOrdersRegistry():void 
		{
			
		}
		
		public function init():void 
		{
			main = Main.ins;
			
			$events = new EventDispatcher();
			
			storeFile = File.applicationStorageDirectory.resolvePath(storeFileName);
			fstream = new FileStream();
			
			// Load file at start
			checkStoreFile();
			
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_SUCCESS, onCheckSuccess);
		}
		
		private function onCheckSuccess(e:EbayHubEvent):void 
		{
			if (e.storeNewEntries == 0) 
				return;
			
			checkStoreFile();
		}
		
		public function getAdrPhone(adrClientName:String, adrLine1:String):String 
		{
			if (xmlDoc == null)
				return null;
				
			var ordersQuery:XMLList = storeEl.Order
				.(stringToLowerCase(ShippingAddress.Street1.@Val as String) == adrLine1.toLowerCase());
			
			var adrClientPhone:String = null;
			var theOrder:XML;
			
			if (ordersQuery.length() > 0)
			{
				theOrder = ordersQuery[0] as XML;
				adrClientPhone = theOrder.ShippingAddress.Phone.@Val;
				
				if (adrClientPhone == "")
					adrClientPhone = null;
			}
			
			return adrClientPhone;
		}
		
		public function getEbayAddress(adrLine1:String):EbayAddress 
		{
			if (xmlDoc == null)
				return null;
				
			var query:XMLList = storeEl.Order.ShippingAddress.(stringToLowerCase(Street1.@Val) == adrLine1.toLowerCase());
			var shipAdrEl:XML;
			var ebayAdr:EbayAddress = null;
			
			if (query.length() > 0) 
			{
				shipAdrEl = query[0] as XML;
				
				ebayAdr = readEbayAddressFromXML(shipAdrEl);
			}
			
			return ebayAdr;
		}
		
		public function getEbayAddressViaOrderID(ebayOrderID:String):EbayAddress 
		{
			if (xmlDoc == null)
				return null;
			
			var query:XMLList;
			var shipAdrEl:XML;
			var ebayAdr:EbayAddress = null;
			
			query = storeEl.Order.(OrderID.@Val == ebayOrderID);
			
			if (query.length() > 0) 
			{
				query = (query[0] as XML).ShippingAddress;
				
				if (query.length() == 0) 
					return null;
				else
					shipAdrEl = query[0] as XML;
					
				ebayAdr = readEbayAddressFromXML(shipAdrEl);
			}
			
			return ebayAdr;
		}
		
		private function readEbayAddressFromXML(shippingAdrXmlEl:XML):EbayAddress 
		{
			var ebayAdr:EbayAddress = new EbayAddress();
			ebayAdr.clientName = shippingAdrXmlEl.ClientName.@Val;
			ebayAdr.country = shippingAdrXmlEl.CountryName.@Val;
			ebayAdr.region = shippingAdrXmlEl.Region.@Val;
			ebayAdr.city = shippingAdrXmlEl.City.@Val;
			ebayAdr.street1 = shippingAdrXmlEl.Street1.@Val;
			ebayAdr.street2 = shippingAdrXmlEl.Street2.@Val;
			ebayAdr.postCode = shippingAdrXmlEl.PostCode.@Val;
			ebayAdr.phone = shippingAdrXmlEl.Phone.@Val;
			return ebayAdr;
		}
		
		private function checkStoreFile():void 
		{
			if (!storeFile.exists) 
			{
				return;
			}
			else 
			{
				var storeFileStr:String = readStoreFile();
				
				if (storeFileStr.length == 0) 
					return;
					
				xmlDoc = new XML(storeFileStr);
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_REGISTRY_UPDATED));
			}
		}
		
		private function readStoreFile():String 
		{
			if (!storeFile.exists)
				return null;
			
			var xmlString:String;
			
			fstream.open(storeFile, FileMode.READ);
			xmlString = fstream.readUTFBytes(fstream.bytesAvailable);
			fstream.close();
			
			return xmlString;
		}
		
		private function stringToLowerCase(inputStr:String):String 
		{
			return inputStr != null ? inputStr.toLowerCase() : "";
		}
		
		public function get events():EventDispatcher
		{
			return $events;
		}
	}
}