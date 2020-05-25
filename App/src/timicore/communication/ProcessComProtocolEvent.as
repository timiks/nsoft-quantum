package timicore.communication 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessComProtocolEvent extends Event 
	{
		public static const COM_MESSAGE_RECEIVED:String = "COM_MESSAGE_RECEIVED";
		
		private var $receivedComMessage:ProcessComProtocolMessage;
		
		public function ProcessComProtocolEvent(type:String, receivedComMessage:ProcessComProtocolMessage,
			bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
			$receivedComMessage = receivedComMessage;
		} 
		
		public override function clone():Event 
		{ 
			return new ProcessComProtocolEvent(type, receivedComMessage, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ProcessComProtocolEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get receivedComMessage():ProcessComProtocolMessage 
		{
			return $receivedComMessage;
		}
	}
}