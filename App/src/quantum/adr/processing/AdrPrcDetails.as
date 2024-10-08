package quantum.adr.processing
{

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class AdrPrcDetails
	{
		public static const ERR_ONE_LINE:String = "Одна строка";
		public static const ERR_UNKNOWN_FORMAT:String = "Неизвестный формат";
		public static const ERR_UNKNOWN_EBAY_ORDER_ID:String = "Заказ с таким ID не найден";
		
		private var $message:String;
		private var $templateType:int;
		private var $mode:int;
		private var $phoneNotFound:Boolean = false;
		private var $ebayOrderIdNotFound:Boolean = false;
		private var $clientNameMismatch:Boolean = false;
		
		public function AdrPrcDetails(msg:String, templateType:int = 0, mode:int = 0,
			phoneNotFound:Boolean = false, ebayOrderIdNotFound:Boolean = false, clientNameMismatch:Boolean = false):void
		{
			this.message = msg;
			this.templateType = templateType;
			this.phoneNotFound = phoneNotFound;
			this.ebayOrderIdNotFound = ebayOrderIdNotFound;
			this.clientNameMismatch = clientNameMismatch;
		}
		
		public function get message():String
		{
			return $message;
		}
		
		public function set message(value:String):void
		{
			$message = value;
		}
		
		public function get templateType():int
		{
			return $templateType;
		}
		
		public function set templateType(value:int):void
		{
			$templateType = value;
		}
		
		public function get mode():int 
		{
			return $mode;
		}
		
		public function set mode(value:int):void 
		{
			$mode = value;
		}
		
		public function get phoneNotFound():Boolean 
		{
			return $phoneNotFound;
		}
		
		public function set phoneNotFound(value:Boolean):void 
		{
			$phoneNotFound = value;
		}
		
		public function get ebayOrderIdNotFound():Boolean 
		{
			return $ebayOrderIdNotFound;
		}
		
		public function set ebayOrderIdNotFound(value:Boolean):void 
		{
			$ebayOrderIdNotFound = value;
		}
		
		public function get clientNameMismatch():Boolean 
		{
			return $clientNameMismatch;
		}
		
		public function set clientNameMismatch(value:Boolean):void 
		{
			$clientNameMismatch = value;
		}
	}
}