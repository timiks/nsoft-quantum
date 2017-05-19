package quantum.events {

	import flash.events.Event;
	import flash.filesystem.File;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class DataEvent extends Event {

		public static const DATA_UPDATE:String = "dataUpdate";

		private var $dataFileRef:File;

		public function DataEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, dataFileRef:File = null):void {
			super(type, bubbles, cancelable);
			$dataFileRef = dataFileRef;
		}

		public override function clone():Event {
			return new DataEvent(type, bubbles, cancelable, dataFileRef);
		}

		public override function toString():String {
			return formatToString("DataEvent", "type", "bubbles", "cancelable", "eventPhase");
		}

		public function get dataFileRef():File {
			return $dataFileRef;
		}

	}

}