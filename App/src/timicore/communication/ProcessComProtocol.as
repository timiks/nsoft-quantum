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
		
		public static const MsgType_Plain:int = 0x1;
		public static const MsgType_JSON:int = 0x2;
		public static const MsgType_Signal:int = 0x3; // With no payload data
		
		public static const MsgCode_ComSocketReady:int = 0x1;
		public static const MsgCode_ComSocketError:int = 0x2;
		public static const MsgCode_PlainMessage:int = 0x3;
	}
}