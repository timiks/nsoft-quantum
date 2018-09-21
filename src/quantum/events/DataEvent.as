package quantum.events
{
	import flash.events.Event;
	import flash.filesystem.File;
	
	/**
	* ...
	* @author Tim Yusupov
	*/
	public class DataEvent extends Event
	{
		public static const DATA_UPDATE:String = "dataUpdate";
		public static const DATA_SAVE:String = "dataSave";
		
		private var $entityId:int;
		private var $updatedFieldName:String;
		
		public function DataEvent(type:String, entityId:int = null, updatedFieldName:String = null, 
			bubbles:Boolean = false, cancelable:Boolean = false):void
		{
			super(type, bubbles, cancelable);
			$entityId = entityId;
			$updatedFieldName = updatedFieldName;
		}
		
		public override function clone():Event
		{
			return new DataEvent(type, entityId, updatedFieldName, bubbles, cancelable);
		}
		
		public override function toString():String
		{
			return formatToString("DataEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
		public function get entityId():int 
		{
			return $entityId;
		}
		
		public function get updatedFieldName():String 
		{
			return $updatedFieldName;
		}
	}
}