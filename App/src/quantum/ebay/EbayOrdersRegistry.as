package quantum.ebay 
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
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
		private var adrSimWords:Dictionary;
		
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
			
			var adrSimWordsDeclaration:Array =
			[
				["street", "str", "st"], 
				["avenue", "ave", "av"], 
				["drive", "dr", "drv"], 
				["road", "rd"]
			];
			
			adrSimWords = new Dictionary();
			
			for each (var ar:Array in adrSimWordsDeclaration) 
				for each (var word:String in ar) 
					adrSimWords[word] = ar;
			
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
		
		/*
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
		*/
		
		public function getEbayAddressViaAdrLine1(adrLine1:String):EbayAddress 
		{
			if (xmlDoc == null)
				return null;
			
			var shipAdrEl:XML;
			var ebayAdr:EbayAddress = null;
			var query:XMLList;
			
			// 1: Strict comparison
			
			query = storeEl.Order.ShippingAddress.(stringToLowerCase(Street1.@Val) == adrLine1.toLowerCase());
			
			if (query.length() > 0) 
			{
				shipAdrEl = query[0] as XML;
				ebayAdr = readEbayAddressFromXML(shipAdrEl);
				return ebayAdr;
			}
			
			// 2: Advanced search
			
			const reWordSplit:RegExp = /\b[^\s]+\b/g;
			var word:String;
			var splitWords:Array;
			var selOrder:XML;
			var selOrderID:String;
			var preRating:Dictionary = new Dictionary();
			
			splitWords = adrLine1.match(reWordSplit);
			
			function selectOrders():void 
			{
				for each (selOrder in query) 
				{
					selOrderID = selOrder.OrderID.@Val;
					
					if (preRating[selOrderID] == null)
						preRating[selOrderID] = { orderEntry: selOrder, score: 0 };
					preRating[selOrderID].score++;
				}
			}
			
			for each (word in splitWords) 
			{
				word = word.toLowerCase();
				
				if (adrSimWords[word] != null) 
				{
					var wordSims:Array = adrSimWords[word];
					
					var wstrre:String = wordSims.join("|");
					var wre:RegExp = new RegExp("\\b(" + wstrre + ")\\b", "i");
					
					query = storeEl.Order.(stringToLowerCase(ShippingAddress.Street1.@Val).search(wre) != -1);
					
					if (query.length() > 0) 
						selectOrders();
				}
				else 
				{
					query = storeEl.Order.
						(stringToLowerCase(ShippingAddress.Street1.@Val).search(new RegExp("\\b" + word + "\\b", "i")) != -1);
						
					if (query.length() > 0) 
						selectOrders();
				}
			}
			
			var rating:Array = [];
			for (selOrderID in preRating) 
			{
				rating.push({ order: preRating[selOrderID].orderEntry, score: preRating[selOrderID].score });
			}
			
			if (rating.length > 0) 
			{
				rating = rating.sortOn("score", Array.NUMERIC | Array.DESCENDING);
				
				selOrder = rating[0].order as XML; trace("Adr line › Words score: " + rating[0].score);
				shipAdrEl = selOrder.ShippingAddress[0];
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