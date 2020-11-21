package quantum.ebay 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayAddress 
	{
		private var $clientName:String;
		private var $country:String;
		private var $region:String;
		private var $city:String;
		private var $street1:String;
		private var $street2:String;
		private var $postCode:String;
		private var $phone:String;
			
		public function EbayAddress():void 
		{
			
		}
		
		public function get clientName():String 
		{
			return $clientName;
		}
		
		public function set clientName(value:String):void 
		{
			$clientName = value;
		}
		
		public function get country():String 
		{
			return $country;
		}
		
		public function set country(value:String):void 
		{
			$country = value;
		}
		
		public function get region():String 
		{
			return $region;
		}
		
		public function set region(value:String):void 
		{
			$region = value;
		}
		
		public function get city():String 
		{
			return $city;
		}
		
		public function set city(value:String):void 
		{
			$city = value;
		}
		
		public function get street1():String 
		{
			return $street1;
		}
		
		public function set street1(value:String):void 
		{
			$street1 = value;
		}
		
		public function get street2():String 
		{
			return $street2;
		}
		
		public function set street2(value:String):void 
		{
			$street2 = value;
		}
		
		public function get postCode():String 
		{
			return $postCode;
		}
		
		public function set postCode(value:String):void 
		{
			$postCode = value;
		}
		
		public function get phone():String 
		{
			return $phone;
		}
		
		public function set phone(value:String):void 
		{
			$phone = value != "" ? value : null;
		}
	}
}