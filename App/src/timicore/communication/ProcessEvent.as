package timicore.communication 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessEvent extends Event 
	{
		public static const RESTARTED:String = "RESTARTED";
		public static const RESTART_OVERFLOW:String = "RESTART_OVERFLOW";
		public static const COMMUNICATION_ERROR:String = "COMMUNICATION_ERROR";
		public static const SYSTEM_ERROR:String = "SYSTEM_ERROR";
		
		public function ProcessEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new ProcessEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ProcessEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
	}
}