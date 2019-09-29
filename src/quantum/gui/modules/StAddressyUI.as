package quantum.gui.modules {

	import fl.controls.TextArea;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.TimerEvent;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import quantum.events.SettingEvent;
	import quantum.gui.Colors;
	import quantum.gui.UIComponentsMgr;

	import quantum.Main;
	import quantum.adr.FormatMgr;
	import quantum.Settings;
	import quantum.adr.processing.ProcessingDetails;
	import quantum.adr.processing.ProcessingResult;
	import quantum.adr.processing.ResultObject;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class StAddressyUI extends Sprite {

		private var main:Main;
		private var ui:AddressyUI;

		private var win:NativeWindow;
		private var tmr:Timer;
		private var modeCopy:Boolean;
		private var resultStr:String; // Хранит обработанный и отформатированный результат
		private var testFlag:Boolean = true;
		private var inited:Boolean = false; // Identifies whether the state is ready

		// ================================================================================

		public function StAddressyUI():void {
			//stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {

			removeEventListener(Event.ADDED_TO_STAGE, init);

			main = Main.ins;

			// State visual composition
			ui = new AddressyUI();
			addChild(ui);

			/**
			 * Window
			 * ================================================================================
			 */

			var winOpts:NativeWindowInitOptions = new NativeWindowInitOptions();
			winOpts.transparent = false;
			winOpts.systemChrome = NativeWindowSystemChrome.STANDARD;
			winOpts.type = NativeWindowType.NORMAL;
			winOpts.maximizable = false;
			winOpts.resizable = false;
			//winOpts.owner = main.stQuantumMgr.stage.nativeWindow;

			win = new NativeWindow(winOpts);
			win.stage.scaleMode = StageScaleMode.NO_SCALE;
			win.stage.align = StageAlign.TOP_LEFT;
			win.stage.stageWidth = 550;
			win.stage.stageHeight = 610;
			//win.visible = true;
			win.title = "Addressy";

			win.stage.addChild(this);

			/*
			// Remembering win position
			var winPosStr:String = main.settings.getKey(Settings.winPos);
			var reResult:Array = winPosStr.match(/(\d+):(\d+)/);
			win.x = Number(reResult[1]);
			win.y = Number(reResult[2]);

			win.addEventListener(NativeWindowBoundsEvent.MOVE, function(e:NativeWindowBoundsEvent):void {
				main.settings.setKey(Settings.winPos, win.x + ":" + win.y);
			});
			*/

			win.addEventListener(Event.CLOSING, function(e:Event):void {
				e.preventDefault();
				win.visible = false;
			});

			/**
			 * UI functionality
			 * ================================================================================
			 */

			// Show Version
			ui.tfVer.text = "";
			//ui.tfVer.autoSize = TextFieldAutoSize.LEFT;
			//if (bugs) ui.tfVer.setTextFormat(new TextFormat(null, null, 0xB11318));

			// Checkbox Automatic Copy in Clipboard
			ui.cbBuf.tabEnabled = false;
			ui.cbBuf.selected = main.settings.getKey(Settings.uiAutomaticCopy);
			ui.cbBuf.addEventListener("change", function(e:Event):void {
				main.settings.setKey(Settings.uiAutomaticCopy, ui.cbBuf.selected);
			});

			// Checkbox Clear Source Area on Success
			ui.cbInpClear.tabEnabled = false;
			ui.cbInpClear.selected = main.settings.getKey(Settings.clearSourceAreaOnSuccess);
			ui.cbInpClear.addEventListener("change", function(e:Event):void {
				main.settings.setKey(Settings.clearSourceAreaOnSuccess, ui.cbInpClear.selected);
			});

			// Checkbox Background Clipboard Processing
			ui.cbBgPrc.tabEnabled = false;
			ui.cbBgPrc.selected = main.settings.getKey(Settings.bgClipboardProcessing);
			ui.cbBgPrc.addEventListener("change", function(e:Event):void {
				main.settings.setKey(Settings.bgClipboardProcessing, ui.cbBgPrc.selected);
			});

			main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onSettingChange);

			// Select Format
			ui.selFormat.tabEnabled = false;
			ui.selFormat.addItem({label: "Шэньчжень (SEO и CFF)", data: FormatMgr.FRM_SHZ1});
			ui.selFormat.addItem({label: "Кантон: формат 2", data: FormatMgr.FRM_CNT_STR2});
			ui.selFormat.addItem({label: "Кантон: формат 1", data: FormatMgr.FRM_CNT_STR1});
			ui.selFormat.addItem({label: "Пекин: строка с разделителем", data: FormatMgr.FRM_BJN_STR});
			ui.selFormat.addItem({label: "Пекин: блок для таблицы", data: FormatMgr.FRM_BJN_BLOCK});
			ui.selFormat.addItem({label: "Пекин: с именами полей", data: FormatMgr.FRM_BJN_TITLES});
			ui.selFormat.addEventListener("change", onSelFormatChange);

			var selItem:Object;
			var setsFormat:String = main.settings.getKey(Settings.outputFormat);
			for (var i:int = 0; i < ui.selFormat.length; i++) {
				selItem = ui.selFormat.getItemAt(i);
				if (selItem.data == setsFormat) {
					ui.selFormat.selectedIndex = i;
					break;
				}
				
				// If last iteration and format obtained from settings is unknown
				if (i == ui.selFormat.length-1)
				{
					ui.selFormat.selectedIndex = ui.selFormat.length-1; // Set to Canton format 2
					main.settings.setKey(Settings.outputFormat,
						ui.selFormat.getItemAt(ui.selFormat.selectedIndex).data); // Incorporate the change in settings
				}
			}

			// Source Text Area
			ui.taL.setFocus();
			ui.taL.addEventListener("change", onTextChange);
			ui.taL.addEventListener(FocusEvent.FOCUS_IN, taLfocusIn);
			ui.taL.addEventListener(FocusEvent.FOCUS_OUT, taLfocusOut);

			// Highlight Rectangle
			ui.outHL.mouseEnabled = false;

			// Buttons
			ui.btnOwnAddr.tabEnabled = false;
			ui.btnOwnAddr.addEventListener(MouseEvent.CLICK, btnOwnAddrClick);
			ui.btnCopyQue.tabEnabled = false;
			ui.btnCopyQue.addEventListener(MouseEvent.CLICK, btnCopyQueClick);

			// Styles
			var uicm:UIComponentsMgr = main.uiCmpMgr;

			uicm.setStyle(ui.taL);
			uicm.setStyle(ui.taR);
			uicm.setStyle(ui.btnOwnAddr);
			uicm.setStyle(ui.btnCopyQue);
			uicm.setStyle(ui.cbBuf);
			uicm.setStyle(ui.cbInpClear);
			uicm.setStyle(ui.cbBgPrc);
			uicm.setStyle(ui.selFormat);
			uicm.setStyle(ui.selFormat.textField);
			uicm.setStyle(ui.selFormat.dropdown);
			uicm.setStyle(ui.lbFormat);

			ui.previewTF.defaultTextFormat = new TextFormat("Tahoma", 12, 0x636363);
			ui.previewTF.htmlText = "";

			// Keyboard
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

			// ================================================================================

			// Stage Settings
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.align = StageAlign.TOP;

			// Ready for Action
			setStatus("Готова", "ok");
			inited = true;

		}

		private function onSettingChange(e:SettingEvent):void {
			if (e.settingName == Settings.bgClipboardProcessing) {
				if (!(ui.cbBgPrc.selected == e.newValue)) {
					ui.cbBgPrc.selected = e.newValue;
				}
			}
		}

		private function taLfocusIn(e:FocusEvent):void {
			setStatus("Готова", "ok");
		}

		private function taLfocusOut(e:FocusEvent):void {
			setStatus("•••", "warn");
		}

		private function keyDown(e:KeyboardEvent):void {
			// ESC
			if (e.keyCode == Keyboard.ESCAPE) {

				win.visible = false;

			} else

			// CTRL + SHIFT + ALT
			if (e.keyCode == Keyboard.ALTERNATE && e.ctrlKey && e.shiftKey) {

				copyQue();

			} else

			// F8
			if (e.keyCode == Keyboard.F8) {

				ui.taL.text = "";
				ui.taL.text = main.prcEng.getRandomAddress();
				onTextChange(null);

			} else

			// CTRL + Z
			if (e.keyCode == Keyboard.Z && e.ctrlKey) {

				ui.taL.text = "";

			} else

			// F5
			if (e.keyCode == Keyboard.F5) {


			} else

			// F9
			if (e.keyCode == Keyboard.F9) {
				//logRed(stage.nativeWindow.x + " " + stage.nativeWindow.y);
			}
		}

		private function onSelFormatChange(e:Event):void {
			changeResultFormat();

			// Сохранить новое значение
			var currentItem:Object = ui.selFormat.getItemAt(ui.selFormat.selectedIndex);
			main.settings.setKey(Settings.outputFormat, currentItem.data);
			trace("Format Changed");
		}

		private function btnOwnAddrClick(e:MouseEvent):void {
			ui.taL.text = "";

			// Show
			main.prcEng.setOwnAddress();
			showResult(main.prcEng.resultObject);

			// Copy
			var copyResultOutput:String;
			copyResultOutput = copyResult();
			if (copyResultOutput != "") {
				copyResultOutput = ". " + copyResultOutput;
			}

			showPanel("Собственный адрес вставлен" + copyResultOutput, Colors.SUCCESS);
		}

		private function btnCopyQueClick(e:MouseEvent):void {
			copyQue();
		}

		private function onTextChange(e:Event):void {
			/*
			Алгоритм
			+ Retrieve processing result details
			+ if processing ok > showResult, copy etc.
			+ if bad > clearResultArea (taR)
			+ Show panel with corresponding information and color
			*/

			var prcResult:ProcessingResult = main.prcEng.process(ui.taL.text);

			/**
			 * SUCCESS
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_OK) {

				/*
				Алгоритм
				> Show panel with message from Processing details; color it in right color

				showResult {
					> Format result (according to current selected format); get formatted string
					> Show string in Output area
					> Highlight yellow box over output
					> Show preview box with fields
				}

				> Copy result
				*/

				// Show
				showResult(prcResult.resultObj);
				showPanel(prcResult.details.message, Colors.SUCCESS);

				// Copy (with delay)
				var copyResultOutput:String;
				var copyTimer:Timer = new Timer(250, 1);
				copyTimer.addEventListener(TimerEvent.TIMER, timeToCopy);
				copyTimer.start();

				function timeToCopy(e:TimerEvent):void {
					copyResultOutput = copyResult();
					if (copyResultOutput != "") {
						showPanel(copyResultOutput, Colors.SUCCESS);
					}
					copyTimer.removeEventListener(TimerEvent.TIMER, timeToCopy);
				}

				if (main.settings.getKey(Settings.clearSourceAreaOnSuccess)) ui.taL.text = "";

			} else

			/**
			 * ERROR
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_ERROR) {

				clearResultArea();
				if (prcResult.details != null) showPanel(prcResult.details.message, Colors.BAD);

			} else


			/**
			 * WARNING
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_WARN) {

				clearResultArea();
				if (prcResult.details != null) showPanel(prcResult.details.message, Colors.WARN);

			} else

			/**
			 * NOT PROCESSED
			 * ================================================================================
			 */
			if (prcResult.status == ProcessingResult.STATUS_NOT_PROCESSED) {
				clearResultArea();
			}

		}

		private function clearResultArea():void {
			ui.taR.text = "";
			ui.previewTF.htmlText = "";
		}

		private function changeResultFormat():void {
			var resObj:ResultObject = main.prcEng.resultObject;
			if (resObj.name == null) return;

			showResult(resObj);
			var copyOutput:String = copyResult();
			if (copyOutput != "") showPanel(copyOutput, Colors.SUCCESS);
		}

		private function showResult(resultObj:ResultObject):void {

			if (resultObj.name == null) {
				trace("Cannot show result. Result Object is null");
				return;
			}

			var name:String = resultObj.name;
			var country:String = resultObj.country;
			var city:String = resultObj.city;
			var region:String = resultObj.region;
			var postCode:String = resultObj.postCode;
			var addr1:String = resultObj.address1;
			var addr2:String = resultObj.address2;
			var phone:String = resultObj.phone;

			var addrs:String = addr1;
			if (addr2 != null) addrs += ", " + addr2;

			var prevResult:String = ui.taR.text;
			clearResultArea();

			// Format
			var format:String = ui.selFormat.selectedItem.data;
			var formattedStr:String = main.formatMgr.format(resultObj, format);
			ui.taR.text = resultStr = formattedStr;

			// Preview Box
			ui.previewTF.htmlText = "";

			if (addr2 == null) {

				ui.previewTF.htmlText =
					"Имя: <font color=\"#000000\">" +
					name + "</font> • Страна: <font color=\"#000000\">" +
					country + "</font> • Город: <font color=\"#000000\">" +
					city + "</font>\n";
				ui.previewTF.htmlText +=
					"Адрес: <font color=\"#000000\">" +
					addr1 + "</font>\n";
				ui.previewTF.htmlText +=
					"Регион: <font color=\"#000000\">" +
					region + "</font> • Индекс: <font color=\"#000000\">" +
					postCode + "</font>\n";

			} else {

				ui.previewTF.htmlText = "Имя: <font color=\"#000000\">" +
					name + "</font> • Страна: <font color=\"#000000\">" +
					country + "</font> • Город: <font color=\"#000000\">" +
					city + "</font>\n";
				ui.previewTF.htmlText +=
					"Адрес 1: <font color=\"#000000\">" +
					addr1 + "</font> • Регион: <font color=\"#000000\">" +
					region + "</font>\n";
				ui.previewTF.htmlText +=
				"Адрес 2: <font color=\"#000000\">" +
				(addr2 == null ? "[no]" : addr2) + "</font> • Индекс: <font color=\"#000000\">" +
				postCode + "</font>\n";

			}

			// Yellow highlight
			ui.outHL.gotoAndPlay(2);

		}

		private function copyResult():String {
			if (!main.settings.getKey(Settings.uiAutomaticCopy)) return "";

			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, resultStr);
			return "Скопировано в буфер";
		}

		private function copyQue():void {

			var resObj:ResultObject = main.prcEng.resultObject;

			if (resObj.name == null) {
				showPanel("Нечего копировать", Colors.WARN);
				main.logRed("Copy Que cannot start. Result Object is empty");
				return;
			}

			if (modeCopy) return;

			modeCopy = true;

			clearResultArea();

			var btnLabel:String;
			var copyQue:Array = [];
			var copyTimer:Timer;
			var copyCount:uint = 0;
			const copyInterval:int = 250;

			function copyTick(e:TimerEvent):void {
				Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, copyQue[copyCount]);
				ui.taR.appendText(copyQue[copyCount] + "\n");
				ui.outHL.gotoAndPlay(2);
				trace("Copy", copyQue[copyCount], copyCount);
				if (copyCount == copyQue.length-1) {
					showPanel("Нужные поля скопированы в буфер", Colors.SUCCESS);
					//setStatus("Копирование полей завершено успешно", "ok");
					ui.taL.enabled = true;
					ui.selFormat.enabled = true;
					ui.cbBuf.enabled = true;
					ui.cbInpClear.enabled = true;
					ui.btnOwnAddr.enabled = true;
					ui.btnCopyQue.enabled = true;
					ui.btnCopyQue.label = btnLabel;
					ui.cbBgPrc.enabled = true;
					modeCopy = false;
					copyTimer.removeEventListener(TimerEvent.TIMER, copyTick);
				}
				copyCount++;
			}

			if (modeCopy) {
				var addrs:String = resObj.address1;
				if (resObj.address2 != null) addrs += ", " + resObj.address2;

				copyQue = [];
				copyQue.push(resObj.name);
				copyQue.push(resObj.city);
				copyQue.push(resObj.postCode);
				copyQue.push(addrs);
				copyQue.push(resObj.region);

				copyCount = 0;
				copyTimer = new Timer(copyInterval, copyQue.length);
				copyTimer.addEventListener(TimerEvent.TIMER, copyTick);
				copyTimer.start();

				btnLabel = ui.btnCopyQue.label;
				ui.btnCopyQue.label = "Копирование полей...";

				ui.taL.enabled = false;
				ui.selFormat.enabled = false;
				ui.cbBuf.enabled = false;
				ui.cbInpClear.enabled = false;
				ui.btnOwnAddr.enabled = false;
				ui.btnCopyQue.enabled = false;
				ui.cbBgPrc.enabled = false;
			}

		}

		/**
		 * GUI Functions
		 * ================================================================================
		 */

		private function showPanel(text:String, color:String = null):void {
			if (color == null) color = "#000000";
			(ui.infopanel.ipo.tf as TextField).htmlText = colorText(color, text);

			switch (color) {
				case Colors.BAD:
					ui.taL.setStyle("textFormat", new TextFormat("Tahoma", 12, 0xCC171C));
				break;
				case Colors.SUCCESS:
					ui.taL.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x000000));
				break;
				case Colors.WARN:
					ui.taL.setStyle("textFormat", new TextFormat("Tahoma", 12, 0x7D7D7D));
				break;
			}

			/*
			if (color == Colors.SUCCESS) {
				var smallSound:Sound = new soundCompleteClass() as Sound;
				smallSound.play();
			}*/

			if ((ui.infopanel as MovieClip).isPlaying) {
				ui.infopanel.gotoAndPlay(10);
			} else {
				ui.infopanel.gotoAndPlay(1);
			}
		}

		private function setStatus(text:String, type:String):void {
			switch (type) {
				case "ok":
					ui.tfStatus.htmlText = colorText(Colors.SUCCESS, text);
				break;
				case "warn":
					ui.tfStatus.htmlText = colorText(Colors.WARN, text);
				break;
				case "error":
					ui.tfStatus.htmlText = colorText(Colors.BAD, text);
				break;
				default:

				break;
			}
		}

		/**
		 * Paints an HTML-text to hex-color (Format: #000000) and returns HTML-formatted string
		 * @param color Hex-color of paint (Format: #000000)
		 * @param tx Text to be painted
		 * @return
		 */
		private function colorText(color:String, tx:String):String {
			return "<font color=\"" + color + "\">" + tx + "</font>";
		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function showBgProcessingResult(resObj:ResultObject):void {
			showResult(resObj);
			showPanel("Обработано на фоне", Colors.TXLB_PURPLE);
		}

		public function showWindow(act:Boolean):void {

			if (!inited) init();

			if (act == true) {

				if (!isVisible) {
					win.x = (Capabilities.screenResolutionX / 2) - (win.width / 2);
					win.y = (Capabilities.screenResolutionY / 2) - (win.height / 2);
					win.visible = true;
				}

				NativeApplication.nativeApplication.activate(win);

			} else {

				win.visible = false;

				if (main.stQuantumMgr.stage.nativeWindow.visible) main.stQuantumMgr.stage.nativeWindow.activate();

			}

		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		public function get isVisible():Boolean {
			return win.visible;
		}

	}

}