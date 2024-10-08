package quantum.adr.processing
{
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class AdrResult
	{
		private static const defaultPhone:String = "+1234567890";
		
		public var name:String;
		public var country:String;
		public var region:String;
		public var city:String;
		public var address1:String;
		public var address2:String;
		public var postCode:String;
		public var phone:String;
		public var sourceAdr:String;
		public var sourceAdrLines:Array;
		
		public function AdrResult():void
		{
			phone = defaultPhone;
		}
		
		public function reset():void
		{
			name = null;
			country = null;
			region = null;
			city = null;
			address1 = null
			address2 = null;
			postCode = null;
			sourceAdr = null;
			sourceAdrLines = null;
			phone = defaultPhone;
		}
	}
}