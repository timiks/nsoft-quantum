package quantum {

	import fl.controls.TextArea;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import quantum.adr.FormatMgr;
	import quantum.adr.processing.ProcessingResult;
	import quantum.gui.Colors;
	import quantum.gui.GroupsContainer;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class TableDataComposer {

		[Embed(source = "/../lib/icons/adr-ico16-grey.png")]
		private var AdrIcon16Grey:Class;

		private var $adrInputTextArea:TextArea;

		private var tableDataFile:File;
		private var fst:FileStream;
		private var tableDataFileLines:Array;
		private var lineEnding:String;
		private var lastContent:String;
		private var lastResult:ProcessingResult;
		private var shippingValues:Object;
		private var shippingFileLoadingTS:Number;

		private var main:Main;
		private var grpCnt:GroupsContainer;

		public function TableDataComposer(groupsContainer:GroupsContainer, inputTextArea:TextArea):void {

			grpCnt = groupsContainer;
			$adrInputTextArea = inputTextArea;

			main = Main.ins;

		}

		public function init():void {

			// File
			fst = new FileStream();
			tableDataFileLines = [];
			lineEnding = "\r\n"; // Windows style

			// Addressy mini logo on Text Area
			var adrMiniLogo:Sprite = new Sprite();
			var adrMiniLogoVerTF:TextField = new TextField();
			var adrGreyIcon:Bitmap = new AdrIcon16Grey();

			adrMiniLogoVerTF.defaultTextFormat = new TextFormat("Tahoma", 12, 0xB7BABC);
			adrMiniLogoVerTF.antiAliasType = AntiAliasType.ADVANCED;
			adrMiniLogoVerTF.autoSize = TextFieldAutoSize.LEFT;
			adrMiniLogoVerTF.selectable = false;
			adrMiniLogoVerTF.text = main.prcEng.version;

			adrMiniLogo.addChild(adrGreyIcon);
			adrMiniLogo.addChild(adrMiniLogoVerTF);
			adrInputTextArea.addChild(adrMiniLogo);

			adrMiniLogoVerTF.x = adrGreyIcon.width;
			adrMiniLogoVerTF.y -= 2;
			adrMiniLogo.x = adrInputTextArea.width - adrMiniLogo.width - 2;
			adrMiniLogo.y = adrInputTextArea.height - adrMiniLogo.height - 2;

			// Listeners
			adrInputTextArea.addEventListener("change", onTextChange);

			lastContent = "";
			lastResult = new ProcessingResult(-1);

			// Shipping file
			loadShippingFile(true);

		}

		private function onTextChange(e:Event):void {

			if (grpCnt.selectedItem == null) return;

			// Process address
			var prcResult:ProcessingResult = main.prcEng.process(adrInputTextArea.text);

			/**
			 * SUCCESS
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_OK) {

				var groupWarehouse:String = grpCnt.selectedItem.parentItemsGroup.warehouseID;
				var groupTitle:String = grpCnt.selectedItem.parentItemsGroup.title;
				var itemImgPath:String = grpCnt.selectedItem.imagePath;
				var processedAddress:String;
				var composedLine:String;

				tableDataFile =
					File.applicationStorageDirectory.resolvePath(
						(groupWarehouse == Warehouse.CANTON ? "canton" : "beijing") + ".txt"
					);

				processedAddress =
					groupWarehouse == Warehouse.CANTON ?
						main.formatMgr.format(prcResult.resultObj, FormatMgr.FRM_CNT_WH) :
						main.formatMgr.format(prcResult.resultObj, FormatMgr.FRM_STR);

				// Read file into memory (to tableDataFileLines)
				readFile();

				// Check group existence
				var groupExistInFile:Boolean;
				var emptyFile:Boolean;
				var l:int = tableDataFileLines.length;

				if (l == 0) {
					groupExistInFile = false;
					emptyFile = true;
				}

				else {

					var line:String;
					var searchResult:int;
					var foundGroupIndex:int;
					var i:int;

					var groupSearchPattern:RegExp = new RegExp(
						groupWarehouse == Warehouse.CANTON ?
							groupTitle :
							"^" + groupTitle
					);

					for (i = 0; i < l; i++) {

						line = tableDataFileLines[i];
						searchResult = line.search(groupSearchPattern);

						if (searchResult != -1) {
							foundGroupIndex = i;
							groupExistInFile = true;
							break;
						}

					}

				}

				// Date
				var date:Date = new Date();
				var dtf:DateTimeFormatter = new DateTimeFormatter("ru-RU");
				var dstr:String;
				dtf.setDateTimePattern("dd.MM.yyyy");
				dstr = dtf.format(date);

				// Shipping column value
				loadShippingFile();
				var shippingValue:String = getCntShippingValue(prcResult.resultObj.country);

				// Compose line
				composedLine = groupWarehouse == Warehouse.CANTON ?

					// Canton
					(emptyFile ? dstr : "") + "\t" +
					(groupExistInFile ? "\t\t" : "ZTO" + "\t" + groupTitle + "\t" + "ship pcs") + "\t" +
					(emptyFile ? "1" : "") + "\t" +
					itemImgPath + "\t" + "1" + "\t" + processedAddress +
					(shippingValue != null ? "\t" + shippingValue : "")

					// [Else (if not Canton) ↓]
					:

					// Beijing
					(groupExistInFile ? "" : groupTitle) + "\t\t" + itemImgPath + "\t" + processedAddress;

				// Add line to file lines
				if (groupExistInFile) {

					tableDataFileLines.splice(foundGroupIndex+1, 0, composedLine); // Add after line with group title

				} else {

					tableDataFileLines.push(composedLine);

				}

				// Write file back
				saveFile();

				// Decrease items quantity
				grpCnt.selectedItem.count--;

				// Sound
				main.soundMgr.play(SoundMgr.sndPrcSuccess);
				
				// Message
				main.stQuantumMgr.infoPanel.showMessage(
					"Товар оформлен для " + prcResult.resultObj.name +
					" в " + prcResult.resultObj.country + " из склада " +
					"«" + Warehouse.getRussianTitle(groupWarehouse) + "»",
					Colors.SUCCESS
				);

				// Clear text area (success)
				adrInputTextArea.text = "";
				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x000000));

			} else

			/**
			 * ERROR
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_ERROR) {

				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0xCC171C));

				// Sound
				if (lastResult.status != prcResult.status) main.soundMgr.play(SoundMgr.sndPrcError);

			} else


			/**
			 * WARNING
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_WARN) {

				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x7D7D7D));

				// Sound
				if (lastResult.status != prcResult.status) main.soundMgr.play(SoundMgr.sndPrcError);

			} else

			/**
			 * NOT PROCESSED
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_NOT_PROCESSED) {

				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x000000));

			}

			lastContent = adrInputTextArea.text;
			lastResult = prcResult;

		}

		private function readFile():void {

			tableDataFileLines = [];

			// Check file
			if (!tableDataFile.exists) {
				return;
			}

			// Read file content
			fst.open(tableDataFile, FileMode.READ);
			var fileStr:String = fst.readUTFBytes(fst.bytesAvailable);
			fst.close();

			// > check CRLF. if not > error
			/*
			if (fileStr.search(lineEnding) == -1) {
				// [To-Do Here ↓]: Вывод глобальной ошибки
				return;
			}
			*/

			tableDataFileLines = fileStr.split(lineEnding);

			if (tableDataFileLines.length == 1 && tableDataFileLines[0] == "") tableDataFileLines.shift();

		}

		private function saveFile():void {

			var fileStr:String = "";
			var line:String;
			var i:int;
			var len:int = tableDataFileLines.length;
			for (i = 0; i < len; i++) {

				line = tableDataFileLines[i];
				fileStr += (i < len-1) ? line + lineEnding : line;

			}

			fst.open(tableDataFile, FileMode.WRITE);
			fst.writeUTFBytes(fileStr);
			fst.close();

		}

		private function getCntShippingValue(cnt:String):String {

			var shipStr:String = null;

			if (shippingValues[cnt] != null)
				shipStr = shippingValues[cnt] as String;

			return shipStr;

		}

		private function loadShippingFile(firstTime:Boolean = false):void {

			// Shipping text file
			var shippingFile:File = File.applicationStorageDirectory.resolvePath("shipping.txt");

			if (shippingFile.exists) {
				if (shippingFile.modificationDate.time < shippingFileLoadingTS)
					if (!firstTime) return;
			}

			if (!shippingFile.exists) {
				fst = new FileStream();
				fst.open(shippingFile, FileMode.WRITE);
				fst.writeUTFBytes(shippingFileDefaultContent);
				fst.close();
			}

			// Load shipping file
			fst = new FileStream();
			fst.open(shippingFile, FileMode.READ);
			var shippingFileString:String = fst.readUTFBytes(fst.bytesAvailable);
			fst.close();

			shippingValues = parseShippingFile(shippingFileString);
			shippingFileLoadingTS = new Date().getTime();

		}

		private function parseShippingFile(fileString:String):Object {

			var file:String = fileString;
			var lineEnding:String = "\r\n"; // Windows style

			// > check CRLF. if not > error
			if (file.search(lineEnding) == -1) {
				//outputLogLine("Ошибка в файле Shipping: Wrong Line Ending", COLOR_BAD);
				return null;
			}

			var shipValues:Object = {};
			var reAr:Array = [];
			var re1:RegExp = /^(.+) \[(.+)\]/;

			var cnt:String;
			var shipStr:String;

			var lines:Array = file.split(lineEnding);

			for each (var line:String in lines) {

				// Comment
				if (line.search(/^# ?/) != -1)
					continue;

				// Empty Line
				if (line == "")
					continue;

				if (line.search(re1) == -1) {
					//outputLogLine("Ошибка в строке файла Shipping: " + line, COLOR_BAD);
					continue;
				}

				reAr = line.match(re1);
				cnt = reAr[1];
				shipStr = reAr[2];

				shipValues[cnt] = shipStr;
			}

			return shipValues;

		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		public function launchAdrProcessing():void {
			if (adrInputTextArea.text == "") return;
			onTextChange(null);
		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		public function get adrInputTextArea():TextArea {
			return $adrInputTextArea;
		}

		// ================================================================================

		private const shippingFileDefaultContent:String = "# Значения колонки Shipping на основе страны адреса\r\n# Формат отдельной строки:\r\n# Country [shipping_value]\r\n\r\n";
	}

}