package quantum
{
	import fl.controls.CheckBox;
	import fl.controls.TextArea;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.text.TextFormat;
	import quantum.adr.FormatMgr;
	import quantum.adr.processing.ProcessingResult;
	import quantum.data.DataMgr;
	import quantum.gui.Colors;
	import quantum.gui.ItemsGroup;
	import quantum.gui.modules.GroupsContainer;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	import quantum.warehouse.Warehouse;
	import timicore.TimUtils;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class TableDataComposer
	{
		[Embed(source = "/../lib/app-icons/adr-ico16-grey.png")]
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
		private var pm:ProductsMgr;
		
		public function TableDataComposer(groupsContainer:GroupsContainer, inputTextArea:TextArea):void
		{
			grpCnt = groupsContainer;
			$adrInputTextArea = inputTextArea;
			
			main = Main.ins;
			pm = main.stQuantumMgr.productsMgr;
		}
		
		public function init():void
		{
			// File
			fst = new FileStream();
			tableDataFileLines = [];
			lineEnding = "\r\n"; // Windows style
			
			// Addressy mini logo on Text Area
			var adrMiniLogo:Sprite = new Sprite();
			var adrGreyIcon:Bitmap = new AdrIcon16Grey();
			
			adrMiniLogo.addChild(adrGreyIcon);
			adrInputTextArea.addChild(adrMiniLogo);
			
			adrMiniLogo.x = adrInputTextArea.width - adrMiniLogo.width - 6;
			adrMiniLogo.y = adrInputTextArea.height - adrMiniLogo.height - 6;
			main.stQuantumMgr.hintMgr.registerHint(adrMiniLogo, "Powered by Addressy™");
			
			var cb:CheckBox = new CheckBox();
			cb.label = "";
			cb.width = 23;
			cb.x = adrInputTextArea.width - cb.width - 2;
			cb.y = 2;
			adrInputTextArea.addChild(cb);
			main.stQuantumMgr.hintMgr.registerHint(cb, "Активировать обработку");
			
			cb.selected = main.settings.getKey(Settings.composerAdrProcessingActive);
			cb.addEventListener("change", function(e:Event):void
			{
				main.settings.setKey(Settings.composerAdrProcessingActive, cb.selected);
			});
			
			// Listeners
			adrInputTextArea.addEventListener("change", onTextChange);
			
			lastContent = "";
			lastResult = new ProcessingResult(-1);
			
			// Shipping file
			loadShippingFile(true);
		}
		
		private function onTextChange(e:Event):void
		{
			if (!main.settings.getKey(Settings.composerAdrProcessingActive))
				return;
			
			if (grpCnt.selectedItem == null) return;
			
			if (grpCnt.selectedItem.parentItemsGroup.title == ItemsGroup.UNTITLED_GROUP_SIGN)
			{
				main.stQuantumMgr.infoPanel.showMessage("Нельзя оформлять товар из безымянной группы", Colors.BAD);
				return;
			}
			
			// Process address
			var prcResult:ProcessingResult = main.prcEng.process(adrInputTextArea.text);
			
			/**
			 * SUCCESS
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_OK)
			{
				composeAndPack(prcResult);
				
				// Clear text area (success)
				adrInputTextArea.text = "";
				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x000000));
			} 
			
			else
			
			/**
			 * ERROR
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_ERROR)
			{
				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0xCC171C));
				
				// Sound
				if (lastResult.status != prcResult.status) main.soundMgr.play(SoundMgr.sndError);
			}
			
			else
			
			/**
			 * WARNING
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_WARN)
			{
				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x7D7D7D));
				
				// Sound
				if (lastResult.status != prcResult.status) main.soundMgr.play(SoundMgr.sndError);
			}
			
			else
			
			/**
			 * NOT PROCESSED
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_NOT_PROCESSED)
			{
				adrInputTextArea.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x000000));
			}
			
			lastContent = adrInputTextArea.text;
			lastResult = prcResult;
		}
		
		private function composeAndPack(adrPrcResult:ProcessingResult):void 
		{
			var groupWarehouse:String = grpCnt.selectedItem.parentItemsGroup.warehouseID;
			var groupTitle:String = grpCnt.selectedItem.parentItemsGroup.title;
			
			if (groupWarehouse == Warehouse.NONE) 
			{
				main.stQuantumMgr.infoPanel.showMessage("Товар находится в группе без склада. Оформление невозможно", Colors.WARN);
				return;
			}
			
			// Special pre-checks
			if (groupWarehouse == Warehouse.SHENZHEN_SEO || groupWarehouse == Warehouse.SHENZHEN_CFF) 
			{
				var itemProductSKU:String = pm.opProduct(grpCnt.selectedItem.productID, DataMgr.OP_READ, Product.prop_sku);
				
				if (itemProductSKU == "")
				{
					main.stQuantumMgr.infoPanel.showMessage("У товара не указан SKU. Оформление отменено", Colors.BAD);
					return;
				}
			}
			
			// Set up variables that differ based on specific warehouse
			// WHT — Warehouse Type
			// · Common
			var WHT_tableDataFileTitle:String;
			var WHT_adrPrcFormat:String;
			var WHT_composingLineTemplateExecutor:Function;
			var WHT_linesGroupSearchPattern:String;
			
			switch (groupWarehouse) 
			{
				case Warehouse.CANTON:
					WHT_tableDataFileTitle = "canton";
					WHT_adrPrcFormat = FormatMgr.FRM_CNT_STR2;
					WHT_linesGroupSearchPattern = groupTitle;
					WHT_composingLineTemplateExecutor = cmpLnTplExtr_Canton2;
					break;
					
				case Warehouse.BEIJING:
					WHT_tableDataFileTitle = "beijing";
					WHT_adrPrcFormat = FormatMgr.FRM_BJN_STR;
					WHT_linesGroupSearchPattern = "^" + groupTitle;
					WHT_composingLineTemplateExecutor = cmpLnTplExtr_BeijingStr;
					break;
					
				case Warehouse.SHENZHEN_SEO:
					WHT_tableDataFileTitle = "shenzhen-seo";
					WHT_adrPrcFormat = FormatMgr.FRM_SHZ1;
					WHT_linesGroupSearchPattern = adrPrcResult.resultObj.name;
					WHT_composingLineTemplateExecutor = cmpLnTplExtr_Shenzhen;
					break;
					
				case Warehouse.SHENZHEN_CFF:
					WHT_tableDataFileTitle = "shenzhen-cff";
					WHT_adrPrcFormat = FormatMgr.FRM_SHZ1;
					WHT_linesGroupSearchPattern = adrPrcResult.resultObj.name;
					WHT_composingLineTemplateExecutor = cmpLnTplExtr_Shenzhen;
					break;
					
				default:
					throw new Error("Out of possible warehouse types");
					break;
			}
			
			// ================================================================================
			
			var processedAddress:String;
			var composedLine:String;
			
			// Prepare concrete file (based on specific warehouse)
			tableDataFile = File.applicationStorageDirectory.resolvePath(WHT_tableDataFileTitle + ".txt");
			
			// Format address
			processedAddress = main.formatMgr.format(adrPrcResult.resultObj, WHT_adrPrcFormat);
			
			// Read file into memory (to tableDataFileLines)
			readFile();
			
			// Check lines group existence
			var linesGroupExistInFile:Boolean = false;
			var emptyFile:Boolean;
			var l:int = tableDataFileLines.length;
			
			if (l == 0)
			{
				linesGroupExistInFile = false;
				emptyFile = true;
			}
			
			else 
			{
				var line:String;
				var searchResult:int;
				var foundLinesGroupIndex:int;
				var i:int;
				
				var groupSearchPattern:RegExp = new RegExp(WHT_linesGroupSearchPattern);
				
				for (i = 0; i < l; i++)
				{
					line = tableDataFileLines[i];
					searchResult = line.search(groupSearchPattern);

					if (searchResult != -1)
					{
						foundLinesGroupIndex = i;
						linesGroupExistInFile = true;
						break;
					}
				}
			}
			
			// Canton specific — date
			if (groupWarehouse == Warehouse.CANTON) 
			{
				// Date
				var date:Date = new Date();
				var dtf:DateTimeFormatter = new DateTimeFormatter("ru-RU");
				var dstr:String;
				dtf.setDateTimePattern("dd.MM.yyyy");
				dstr = dtf.format(date);
			}
			
			// Canton / Beijing specific — image file path
			if (groupWarehouse == Warehouse.BEIJING || groupWarehouse == Warehouse.CANTON) 
			{
				// Item's image path
				var itemImgPath:String = grpCnt.selectedItem.imagePath;
			}
			
			// Shipping column value
			loadShippingFile();
			var shippingValue:String = getCntShippingValue(adrPrcResult.resultObj.country, groupWarehouse);
			
			// Compose line
			composedLine = WHT_composingLineTemplateExecutor() as String;
			
			// Add line to file lines
			if (linesGroupExistInFile)
			{
				/* Add new line after line with lines group header */
				tableDataFileLines.splice(foundLinesGroupIndex+1, 0, composedLine);
				
				// [!] Shenzhen warehouses specific check
				if (groupWarehouse == Warehouse.SHENZHEN_SEO || groupWarehouse == Warehouse.SHENZHEN_CFF) 
				{
					var linesGroupHeaderLine:String = tableDataFileLines[foundLinesGroupIndex];
					if (shippingValue != null && linesGroupHeaderLine.search(/^\t{4}/) != -1) 
					{
						// Add missing shipping value to the header line (if it wasn't)
						linesGroupHeaderLine = linesGroupHeaderLine.replace(/^\t{4}/, "\t\t" + shippingValue + "\t\t");
						tableDataFileLines[foundLinesGroupIndex] = linesGroupHeaderLine;
					}
				}
			}
			else 
			{
				/* Add lines group header line to the end */
				tableDataFileLines.push(composedLine);
			}
			
			// Write file back
			saveFile();
			
			// Success sound
			main.soundMgr.play(SoundMgr.sndSuccess, true);
			
			// Item title to show in message
			var itemTitle:String = null;
			if (groupWarehouse == Warehouse.SHENZHEN_SEO || groupWarehouse == Warehouse.SHENZHEN_CFF) 
			{
				itemTitle = itemProductSKU;
			}
			
			// Success message
			main.stQuantumMgr.infoPanel.showMessage
			(
				(itemTitle != null ? itemTitle + " • " : "") + adrPrcResult.resultObj.name +
				(adrPrcResult.resultObj.country != null ? " (" + adrPrcResult.resultObj.country + ") • " : " • ") +
				"Склад: «" + Warehouse.getByID(groupWarehouse).russianTitle + "»" + " • <b>Оформлено</b>",
				Colors.SUCCESS, true
			);
			
			// Decrease items quantity
			grpCnt.selectedItem.count--;
			
			/**
			 * Composing Line Template Executors
			 * ================================================================================
			 */
			
			function cmpLnTplExtr_Shenzhen():String 
			{
				var outputLine:String;
				
				outputLine = 
				
				// Col A, B: {skip}
				"\t\t" +
				// Col C: Shipping
				(linesGroupExistInFile ? "\t" : (shippingValue != null ? shippingValue + "\t" : "\t")) +
				// Col D: {skip}
				"\t" +
				// Col E-L: {Address fields} (processed by Addressy)
				(linesGroupExistInFile ? "\t\t\t\t\t\t\t\t" : processedAddress + "\t") +
				// Col M, N, O: {skip}
				"\t\t\t" +
				// Col P: Product's SKU
				itemProductSKU + "\t" +
				// Col Q-T: ...
				"toy" + "\t" + "玩具" + "\t" +
				"1\t1" + "\t" +
				// Col U: {skip}
				"\t" +
				// Col V: ...
				"0.1" + "\t" +
				// Col W, X: {skip}
				"\t\t" +
				// Col Y: ...
				"0";
				
				return outputLine;
			} 
			 
			function cmpLnTplExtr_Canton2():String
			{
				var outputLine:String;
				
				outputLine =
				
				// Col A: Date
				(emptyFile ? dstr : "") + "\t" +
				
				// Col B: Shipping company (hard coded value: "ZTO")
				// Col C: Parcel number
				// Col D: Products
				(linesGroupExistInFile ? "\t\t" : "ZTO" + "\t" + groupTitle + "\t" + "ship pcs") + "\t" +
				
				// Col E: Parcel NO. (hard coded value: "1")
				(emptyFile ? "1" : "") + "\t" +
				
				// Col F: Quantity (hard coded value: "1")
				// Col G: Picture
				"1" + "\t" + itemImgPath + "\t" + 
				
				// Col H: Shipping
				(shippingValue != null ? shippingValue + "\t" : "\t") +
				
				// Col I–O: {Address fields} (processed by Addressy)
				processedAddress;
				
				return outputLine;
			}
			
			function cmpLnTplExtr_Canton1():String
			{
				var outputLine:String;
				
				outputLine =
				
				// Col A: Date
				(emptyFile ? dstr : "") + "\t" +
				
				// Col B: Shipping company (hard coded value: "ZTO")
				// Col C: Parcel number
				// Col D: Products
				(linesGroupExistInFile ? "\t\t" : "ZTO" + "\t" + groupTitle + "\t" + "ship pcs") + "\t" +
				
				// Col E: Parcel NO. (hard coded value: "1")
				(emptyFile ? "1" : "") + "\t" +
				
				// Col F: Picture
				// Col G: Quantity (hard coded value: "1")
				itemImgPath + "\t" + "1" + "\t" + 
				
				// Col H: Address (combined)
				// Col I: Shipping
				processedAddress + (shippingValue != null ? "\t" + shippingValue : "");
				
				return outputLine;
			}
			
			function cmpLnTplExtr_BeijingStr():String
			{
				var outputLine:String;
				
				outputLine =
				// Col A, B, C: Parcel number, Note (skip), Item
				// Col D–K: Shipping method + {Address fields} (processed by Addressy)
				(linesGroupExistInFile ? "" : groupTitle) + "\t\t" + itemImgPath + "\t" + processedAddress;
				
				return outputLine;
			}
		}
		
		private function readFile():void
		{
			tableDataFileLines = [];
			
			// Check file
			if (!tableDataFile.exists)
				return;
			
			// Read file content
			fst.open(tableDataFile, FileMode.READ);
			var fileStr:String = fst.readUTFBytes(fst.bytesAvailable);
			fst.close();
			
			tableDataFileLines = fileStr.split(lineEnding);
			
			if (tableDataFileLines.length == 1 && tableDataFileLines[0] == "")
				tableDataFileLines.shift();
		}
		
		private function saveFile():void
		{
			var fileStr:String = "";
			var line:String;
			var i:int;
			var len:int = tableDataFileLines.length;
			
			for (i = 0; i < len; i++)
			{
				line = tableDataFileLines[i];
				fileStr += (i < len-1) ? line + lineEnding : line;
			}
			
			fst.open(tableDataFile, FileMode.WRITE);
			fst.writeUTFBytes(fileStr);
			fst.close();
		}
		
		private function getCntShippingValue(cnt:String, whID:String):String
		{
			var shipStr:String = null;
			
			var idx:int;
			switch (whID) 
			{
				case Warehouse.CANTON:
					idx = 0;
					break;
				
				case Warehouse.SHENZHEN_SEO:
					idx = 1;
					break;
					
				case Warehouse.SHENZHEN_CFF:
					idx = 2;
					break;
					
				default:
					shipStr = null;
					return shipStr;
					break;
			}
			
			if (shippingValues[cnt] != null)
				shipStr = shippingValues[cnt][idx] as String;
			
			return shipStr;
		}
		
		private function loadShippingFile(firstTime:Boolean = false):void
		{
			// Shipping text file
			var shippingFile:File = File.applicationStorageDirectory.resolvePath("shipping.txt");
			
			if (shippingFile.exists)
			{
				if (shippingFile.modificationDate.time < shippingFileLoadingTS)
					if (!firstTime) return;
			}
			
			if (!shippingFile.exists)
			{
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

		private function parseShippingFile(fileString:String):Object
		{
			var file:String = fileString;
			var lineEnding:String = "\r\n"; // Windows style
			
			// > check CRLF. if not > error
			if (file.search(lineEnding) == -1)
			{
				//outputLogLine("Ошибка в файле Shipping: Wrong Line Ending", COLOR_BAD);
				return null;
			}
			
			var shipValues:Object = {};
			var reAr:Array = [];
			var re1:RegExp = /^(.+) \[(.+)\]/;
			
			var cnt:String;
			var shipStr:String;
			
			var lines:Array = file.split(lineEnding);
			
			for each (var line:String in lines)
			{
				// Comment
				if (line.search(/^# ?/) != -1)
					continue;
				
				// Empty Line
				if (line == "")
					continue;
				
				if (line.search(re1) == -1)
				{
					/* Unexpected line format > error */
					continue;
				}
				
				reAr = line.match(re1);
				cnt = TimUtils.trimSpaces(reAr[1]);
				shipStr = reAr[2];
				
				var typeValues:Array = shipStr.split("|");
				
				var v:String;
				for (var i:int = 0; i < typeValues.length; i++) 
				{	
					v = typeValues[i];
					
					if (v == "" || v.search(/^\s+$/) != -1) 
					{
						typeValues[i] = null;
					}
					else 
					{
						typeValues[i] = TimUtils.trimSpaces(v);
					}
				}
				
				shipValues[cnt] = typeValues;
			}
			
			return shipValues;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		public function launchAdrProcessing():void
		{
			if (adrInputTextArea.text == "") return;
			onTextChange(null);
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get adrInputTextArea():TextArea
		{
			return $adrInputTextArea;
		}
		
		// ================================================================================
		
		private const shippingFileDefaultContent:String = "# Значения колонки Shipping на основе страны и склада\r\n# Формат отдельной строки:\r\n# Страна [ значение 1 | значение 2 | значение 3 ]\r\n# Порядок для складов: [ 1. Кантон | 2. SEO (Шэньчжэнь) | 3. CFF (Шэньчжэнь) ]\r\n# Пробелы по краям значения не учитываются. Страна на английском.\r\n\r\n";
	}
}