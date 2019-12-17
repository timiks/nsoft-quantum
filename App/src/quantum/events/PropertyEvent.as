package quantum.events 
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class PropertyEvent extends Event 
	{
		public static const CHANGED:String = "propertyChanged";
		
		private var $observablePropertyID:String;
		
		public function PropertyEvent(type:String, observablePropertyID:String, bubbles:Boolean = false, cancelable:Boolean = false):void 
		{ 
			super(type, bubbles, cancelable);
			$observablePropertyID = observablePropertyID;
		} 
		
		public override function clone():Event 
		{ 
			return new PropertyEvent(type, observablePropertyID, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("PropertyEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get observablePropertyID():String 
		{
			return $observablePropertyID;
		}
	}
}