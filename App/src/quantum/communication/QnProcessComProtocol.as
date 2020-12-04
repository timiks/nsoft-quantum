package quantum.communication 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class QnProcessComProtocol 
	{
		public function QnProcessComProtocol():void {}
		
		public static const MsgCode_ExecuteEbayOrdersCheck:int 		= 100; // Signal
		public static const MsgCode_EbayOrdersCheckStarted:int 		= 101; // Signal
		public static const MsgCode_EbayOrdersCheckError:int 		= 102; // +Data
		public static const MsgCode_EbayOrdersCheckSuccess:int 		= 103; // +Data
		public static const MsgCode_EbayOrdersStoreUpdated:int 		= 104; // Signal
		public static const MsgCode_EbayAuthTokenError:int 			= 105; // Signal
		public static const MsgCode_EbayAuthTokenExpiryWarning:int 	= 106; // +Data (plain)
		public static const MsgCode_ClearEbayOrdersCache:int        = 107; // +Signal
        public static const MsgCode_ExecuteEbayOrdersCheckFull:int  = 108; // +Signal
		public static const MsgCode_CancelEbayOrdersCheck:int       = 109; // +Signal
		public static const MsgCode_EbayOrdersCacheCleared:int      = 110; // +Signal
	}
}