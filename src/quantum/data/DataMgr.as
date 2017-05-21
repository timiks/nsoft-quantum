package quantum.data {

	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	import quantum.gui.ItemsGroup;
	import quantum.gui.SquareItem;
	import quantum.Main;
	import quantum.Settings;
	import quantum.Warehouse;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class DataMgr {

		public static const OP_READ:String = "read"; // Not in use
		public static const OP_ADD:String = "add";
		public static const OP_REMOVE:String = "rem";
		public static const OP_UPDATE:String = "upd";

		private static const dataFileVersion:int = 2;

		private var main:Main;

		private var dataXml:XML;
		private var dataFile:File;
		private var fstream:FileStream;

		private var tmrSaveDelay:Timer;
		private var loaded:Boolean = false;

		private var $events:EventDispatcher;

		public function DataMgr():void {}

		public function load():void {
			/*
			Алгоритм
			> check Data File existence in AppData dir
			> 	* if found > parse XML into dataXml object; check for errors
			>	* if not found > create dataXml object with default sets and create Data File
			*/

			main = Main.ins;

			$events = new EventDispatcher();
			dataFile = File.applicationStorageDirectory.resolvePath("data.xml");
			fstream = new FileStream();

			// Data file isn't found
			if (!dataFile.exists) {

				trace("Data File not found");
				initDefXmlAndCreateFile();
				loaded = true;

			}

			// Data file is found
			else {

				trace("Data File found: " + dataFile.nativePath);

				fstream.open(dataFile, FileMode.READ);
				var xmlString:String = fstream.readUTFBytes(fstream.bytesAvailable);
				fstream.close();

				// Empty file
				if (xmlString == "") {

					initDefXmlAndCreateFile();

				}

				// Alright
				else {

					// Construct XML tree from data file
					dataXml = new XML(xmlString);

					// Do some checks and changes
					if (dataXml.@appVersion != main.version)
						dataXml.@appVersion = main.version;

					var dfv:String = dataXml.@dataFileVersion;
					if (dfv == "" || dfv == null)
						dataXml.@dataFileVersion = String(dataFileVersion);

					// {Here should be version check of loaded data file and
					// transforming loaded format to actual version format, if differ}

					// [!] Separate function or module needed

					// Data File v2
					if (int(dfv) < 2) {

						if (dataXml.notes == undefined) {
							dataXml.prependChild(<notes/>);
						}

					}

					// Updating data file version if differs
					if (dataXml.@dataFileVersion != dataFileVersion)
						dataXml.@dataFileVersion = dataFileVersion

				}

				// [To-Do Here ↓]: Errors check

				loaded = true;

			}
		}

		private function initDefXmlAndCreateFile(createFile:Boolean = true):void {

			// Default XML
			dataXml = <quantumData/>;
			dataXml.@appVersion = main.version;
			dataXml.@dataFileVersion = String(dataFileVersion);

			// DF v2 feature
			dataXml.appendChild(<notes/>);

			if (!createFile) return;

			saveFile();

		}

		/**
		 * Вызывать всякий раз при изменении данных, чтобы изменения можно было сохранить на диск
		 */
		private function dataUpdate(delay:int = 3000):void {

			if (tmrSaveDelay == null) {
				tmrSaveDelay = new Timer(delay, 1);
				tmrSaveDelay.addEventListener(TimerEvent.TIMER, saveOnTimer);
				tmrSaveDelay.start();
			}

			events.dispatchEvent(new DataEvent(DataEvent.DATA_UPDATE));

		}

		private function saveOnTimer(e:TimerEvent):void {
			saveFile();
			tmrSaveDelay.removeEventListener(TimerEvent.TIMER, saveOnTimer);
			tmrSaveDelay = null;
		}

		public function saveFile():void {

			if (Capabilities.isDebugger && !DevSettings.dataSaveOn) return;

			// XML output settings
			XML.prettyPrinting = true;
			XML.prettyIndent = 4;

			fstream.open(dataFile, FileMode.WRITE);
			fstream.writeUTFBytes(dataXml.toXMLString());
			fstream.close();

			main.logRed("Data File Saved");

		}

		public function getDataFileRef():File {
			return dataFile;
		}

		/**
		 * DATA MANAGEMENT INTERFACE
		 * ================================================================================
		 */

		public function getAllGroups():Vector.<ItemsGroup> {

			var groups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();

			var newGrp:ItemsGroup;

			// Fields
			var warehouseID:String;
			for each (var grp:XML in dataXml.itemsGroup) {
				warehouseID = grp.@warehouseID;
				// При первом запуске версии с этим полем его не будет у существующих групп
				// Проставить Пекин (Beijing) по умолчанию для тех групп, которые уже есть
				grp.@warehouseID = warehouseID == "" ? Warehouse.BEIJING : warehouseID;

				newGrp = new ItemsGroup(
					grp.@title,
					grp.@warehouseID
				);

				newGrp.dataXml = grp;
				groups.push(newGrp);
			}

			return groups;

		}

		public function getGroupItems(grp:XML):Vector.<SquareItem> {

			var items:Vector.<SquareItem> = new Vector.<SquareItem>();

			var newItem:SquareItem;
			for each (var itm:XML in grp.item) {
				newItem = new SquareItem(itm.@imgPath, int(itm.@count));
				newItem.dataXml = itm;
				items.push(newItem);
			}

			return items;

		}

		public function getAllNotes():Vector.<Object> {

			var notes:Vector.<Object> = new Vector.<Object>();

			for each (var noteRecord:XML in dataXml.notes.itemNote) {

				notes.push({imgPath: noteRecord.@img, noteText: noteRecord.@text});

			}

			return notes;

		}

		public function opNote(op:String, imgPath:String, noteText:String = null):void {

			if (op == OP_UPDATE) {

				dataXml.notes.itemNote.(@img == imgPath)[0].@text = noteText;

			}

			else

			if (op == OP_ADD) {

				var newNote:XML = <itemNote/>
				newNote.@img = imgPath;
				newNote.@text = noteText;
				dataXml.notes.appendChild(newNote);

			}

			else

			if (op == OP_REMOVE) {

				delete dataXml.notes.itemNote.(@img == imgPath)[0];

			}

			dataUpdate(5500);

		}

		public function opGroup(grp:ItemsGroup, op:String, field:String = null, value:* = null):void {

			if (op == OP_UPDATE) {

				grp.dataXml.@[field] = value;

			}

			else

			if (op == OP_ADD) {

				var newGroup:XML = <itemsGroup/>
				newGroup.@title = grp.title;
				newGroup.@warehouseID = grp.warehouseID;
				grp.dataXml = newGroup;
				dataXml.appendChild(newGroup);

			}

			else

			if (op == OP_REMOVE) {

				delete dataXml.children()[grp.dataXml.childIndex()];

			}

			dataUpdate();

		}

		public function opItem(item:SquareItem, op:String, field:String = null, value:* = null):void {

			if (op == OP_UPDATE) {

				item.dataXml.@[field] = value;

			}

			else

			if (op == OP_ADD) {

				var newItem:XML = <item/>;
				newItem.@count = item.count;
				newItem.@imgPath = item.imagePath;

				item.parentItemsGroup.dataXml.appendChild(newItem);
				item.dataXml = newItem;

			}

			else

			if (op == OP_REMOVE) {

				delete item.parentItemsGroup.dataXml.item[item.dataXml.childIndex()];

			}

			dataUpdate();

		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		public function get events():EventDispatcher {
			return $events;
		}

	}

}