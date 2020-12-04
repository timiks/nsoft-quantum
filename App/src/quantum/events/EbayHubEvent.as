package quantum.events 
{
	import flash.events.Event;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayHubEvent extends Event
	{
		public static const ORDERS_CHECK_START_CONFIRMATION_RECEIVED:String = "ORDERS_CHECK_START_CONFIRMATION_RECEIVED";
		public static const ORDERS_CHECK_SUCCESS:String = "ORDERS_CHECK_SUCCESS";
		public static const ORDERS_CHECK_ERROR:String = "ORDERS_CHECK_ERROR";
		public static const ORDERS_REGISTRY_UPDATED:String = "ORDERS_REGISTRY_UPDATED";
		public static const ORDERS_FILE_UPDATED:String = "ORDERS_FILE_UPDATED";
		public static const ORDERS_CACHE_CLEARED:String = "ORDERS_CACHE_CLEARED";
		public static const USER_AUTH_TOKEN_ERROR:String = "AUTH_TOKEN_ERROR";
		public static const PROCESS_RESTART_OVERFLOW:String = "PROCESS_RESTART_OVERFLOW";
		public static const PROCESS_COM_ERROR:String = "PROCESS_COM_ERROR";
		public static const PROCESS_SYS_ERROR:String = "PROCESS_SYS_ERROR";
		public static const PROCESS_FILE_NOT_FOUND:String = "PROCESS_FILE_NOT_FOUND";
		
		private var $storeNewEntries:int;
		
		public function EbayHubEvent(type:String, storeNewEntries:int = 0, bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
			$storeNewEntries = storeNewEntries;
		} 
		
		public override function clone():Event 
		{ 
			return new EbayHubEvent(type, storeNewEntries, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("EbayEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get storeNewEntries():int 
		{
			return $storeNewEntries;
		}
	}
}