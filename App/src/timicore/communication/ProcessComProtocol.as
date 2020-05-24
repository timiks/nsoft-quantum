package timicore.communication 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessComProtocol 
	{
		public function ProcessComProtocol():void {}
		
		public static const DataSeparator:String = String.fromCharCode(0x001E);
		public static const EndOfMessageSign:String = String.fromCharCode(0x0004);
		
		public static const MsgType_Plain:int 	= 1; // With single string data
		public static const MsgType_JSON:int 	= 2; // With JSON-encoded object data
		public static const MsgType_Signal:int 	= 3; // With no payload data
		
		public static const MsgCode_ComSocketReady:int 	= 1;
		public static const MsgCode_ComSocketError:int 	= 2;
		public static const MsgCode_PlainMessage:int 	= 3;
		public static const MsgCode_SysError:int 		= 4; // +Data (plain)
	}
}