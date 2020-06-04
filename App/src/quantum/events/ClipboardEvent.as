package quantum.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ClipboardEvent extends Event 
	{
		public static const CHANGED:String = "CLIPBOARD_CHANGED";
		
		public function ClipboardEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new ClipboardEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ClipboardEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
	}
}