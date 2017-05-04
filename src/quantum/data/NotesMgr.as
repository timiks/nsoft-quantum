package quantum.data {

	import quantum.Main;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class NotesMgr {

		private var main:Main;

		private var records:Object;

		public function NotesMgr():void {}

		public function init():void {

			main = Main.ins;
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
				return;
			}

			main.dataMgr.opNote(records[imgPath] == null ? DataMgr.OP_ADD : DataMgr.OP_UPDATE, imgPath, noteText);

			records[imgPath] = noteText;

		}

	}

}