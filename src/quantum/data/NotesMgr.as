package quantum.data {

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import quantum.Main;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class NotesMgr {

		private var main:Main;

		private var records:Object;

		private var $events:EventDispatcher;

		public function NotesMgr():void {}

		public function init():void {

			main = Main.ins;
			$events = new EventDispatcher();
			records = new Object();

			// Record object format: {imgPath: $, noteText: $})
			var recordsAr:Vector.<Object> = main.dataMgr.getAllNotes();

			if (recordsAr.length == 0) return;

			for each (var rec:Object in recordsAr) {
				records[rec.imgPath] = rec.noteText;
			}

		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function getNote(imgPath:String):String {

			var note:String = records[imgPath];

			return note != null ? note : "";

		}

		public function setNote(imgPath:String, noteText:String):void {

			if (noteText == "") {
				delete records[imgPath];
				main.dataMgr.opNote(DataMgr.OP_REMOVE, imgPath);
				events.dispatchEvent(new Event(Event.CHANGE));
				return;
			}

			main.dataMgr.opNote(records[imgPath] == null ? DataMgr.OP_ADD : DataMgr.OP_UPDATE, imgPath, noteText);
			records[imgPath] = noteText;
			events.dispatchEvent(new Event(Event.CHANGE));

		}

		public function get events():EventDispatcher {
			return $events;
		}

	}

}