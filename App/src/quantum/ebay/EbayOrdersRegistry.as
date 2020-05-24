package quantum.ebay 
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import quantum.Main;
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
			
			checkStoreFile();
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_SUCCESS, onCheckSuccess);
			//getAdrPhone("Richard Altman", "32 E Princeton Rd"); // TEST
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
				.(ShippingAddress.ClientName.@Val == adrClientName && ShippingAddress.Street1.@Val == adrLine1);
			
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
		
		public function get events():EventDispatcher
		{
			return $events;
		}
	}
}