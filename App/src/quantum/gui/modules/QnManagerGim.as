package quantum.gui.modules
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.Settings;
	import quantum.jobs.TableDataComposer;
	import quantum.events.EbayHubEvent;
	import quantum.gui.elements.BigTextInput;
	import quantum.gui.Colors;
	import quantum.gui.HintMgr;
	import quantum.gui.elements.EbayOrdersCheckButton;
	import quantum.gui.elements.QnInfoPanel;
	import quantum.gui.UIComponentsMgr;
	import quantum.gui.modules.GroupsGim;
	import quantum.product.ProductsMgr;
	import timicore.TimUtils;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class QnManagerGim extends Sprite
	{
		private var main:Main;
		private var ui:QnManagerComposition;
		private var win:NativeWindow;
		private var hintsCnt:Sprite;
		
		private var delayedTasksTimer:Timer;
		
		// Public modules
		private var $grpCnt:GroupsGim;
		private var $tableDataComposer:TableDataComposer;
		private var $grpTitleTextInput:BigTextInput;
		private var $ebayOrdersCheckButton:EbayOrdersCheckButton;
		private var $hintMgr:HintMgr;
		private var $infoPanel:QnInfoPanel;
		private var $productsMgr:ProductsMgr;
		
		public function QnManagerGim():void
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			main = Main.ins;
			
			// Stage settings
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// State visual composition
			ui = new QnManagerComposition();
			
			// Window and Tray functionality
			initWindowAndTray();
			
			// App version label
			ui.tfVer.autoSize = TextFieldAutoSize.LEFT;
			ui.tfVer.htmlText = Capabilities.isDebugger && main.isFutureVersion ? 
				colorText(Colors.TXLB_PURPLE, main.version) : 
				(main.isBetaActive ? colorText(Colors.TXLB_TURQUOISE, main.version) : main.version);
			
			/**
			 * UI components
			 * ================================================================================
			 */
			
			// Main buttons (top)
			// · Exit
			ui.btnExit.tabEnabled = false;
			ui.btnExit.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				main.exitApp();
			});
			
			// · Addressy UI show
			ui.btnShowAdrUI.tabEnabled = false;
			ui.btnShowAdrUI.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				main.adrUiGim.showWindow(true);
			});
			
			// · Settings window show
			ui.btnSettings.tabEnabled = false;
			ui.btnSettings.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				main.settingsGim.showWindow(true);
			});
			
			// · New group
			ui.btnNewGroup.tabEnabled = false;
			ui.btnNewGroup.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				grpCnt.addNewGroup();
			});
			
			// · eBay button
			ui.btnEbay.tabEnabled = false;
			ui.btnEbay.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				trace("eBay win open");
				main.ebayGim.showWindow(true);
			});
			
			// Selected item properties editors
			// · Selected item's count (numeric stepper)
			ui.nsCount.addEventListener("change", function(e:Event):void
			{
				grpCnt.updateUiElementData("selItemCount", ui.nsCount.value);
			});
			
			// · Note of product entry of selected item (text area)
			ui.taDetails.addEventListener("change", function(e:Event):void
			{
				grpCnt.updateUiElementData("selItemTypeNotes", ui.taDetails.text);
			});
			
			// · Price of product entry of selected item (text input) 
			ui.tiPrice.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductPrice", ui.tiPrice.text == "" ? 0 : checkDecimalInputFormat(ui.tiPrice.text));
			});
			ui.tiPrice.textField.addEventListener(TextEvent.TEXT_INPUT, validateDecimalInput);
			
			// · Weight of product entry of selected item (text input)
			ui.tiWeight.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductWeight", ui.tiWeight.text == "" ? 0 : checkDecimalInputFormat(ui.tiWeight.text));
			});
			ui.tiWeight.textField.addEventListener(TextEvent.TEXT_INPUT, validateDecimalInput);
			
			// · SKU of product entry of selected item (text input)
			ui.tiSku.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductSKU", TimUtils.trimSpaces(ui.tiSku.text));
			});
			
			// Styles
			var uicm:UIComponentsMgr = main.uiCmpMgr;
			uicm.setStyle(ui.taAdr);
			uicm.setStyle(ui.nsCount);
			uicm.setStyle(ui.nsCount.textField);
			uicm.setStyle(ui.taDetails);
			uicm.setStyle(ui.tiSku);
			uicm.setStyle(ui.tiPrice);
			uicm.setStyle(ui.tiWeight);
			uicm.setStyle(ui.btnEbayOrdersCheck);
			
			// Show whole composition after everything looks well
			addChild(ui);
			
			/**
			 * Sub modules (private & public)
			 * ================================================================================
			 */
			
			// Hint manager
			hintsCnt = new Sprite;
			$hintMgr = new HintMgr();
			$hintMgr.init(hintsCnt);
			
			if (main.isBetaActive)
				hintMgr.registerHint(ui.tfVer, "Бета-версия\n" + colorText(Colors.TXLB_LIGHT_GREY, "В процессе тестирования"));
			
			// Info panel
			$infoPanel = new QnInfoPanel(ui.infopanel);
			ui.infopanel.y = 590 - 48;
			$infoPanel.init();
			
			// Products manager
			$productsMgr = new ProductsMgr();
			$productsMgr.init();
			
			// Groups Container
			$grpCnt = new GroupsGim(this);
			
			// Table data composer
			$tableDataComposer = new TableDataComposer(grpCnt, ui.taAdr);
			$tableDataComposer.init();
			
			// Group title text input
			$grpTitleTextInput = new BigTextInput();
			$grpTitleTextInput.tf = ui.tiGrpTitle;
			$grpTitleTextInput.init(this, grpCnt, ui.tfstripe);
			
			// Ebay orders check button
			$ebayOrdersCheckButton = new EbayOrdersCheckButton(ui.btnEbayOrdersCheck);
			$ebayOrdersCheckButton.init();
			
			// Layers display order
			ui.addChildAt(grpCnt, 0);
			addChildAt(hintsCnt, numChildren);
			
			// Register hints for UI elements
			hintMgr.registerHint(ui.nsCount, "Количество товара в группе");
			hintMgr.registerHint(ui.taDetails, "Заметка");
			hintMgr.registerHint(ui.tiPrice, "Цена товара (в USD)");
			hintMgr.registerHint(ui.tiSku, "Значение SKU");
			hintMgr.registerHintWithHandler(ui.tiWeight, grpCnt.selItemWeightEditHintTextHandler);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			
			// Task in the callback will be executed with specified delay after UI has shown up
			delayedTasksTimer = new Timer(500, 1);
			delayedTasksTimer.addEventListener(TimerEvent.TIMER_COMPLETE, executeAfterDelay);
			delayedTasksTimer.start();
		}
		
		private function executeAfterDelay(e:TimerEvent):void 
		{
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_SUCCESS, onEbayHubEvent);
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_ERROR, onEbayHubEvent);
			main.ebayHub.SendCheckSignal();
		}
		
		private function onEbayHubEvent(e:EbayHubEvent):void 
		{
			main.ebayHub.events.removeEventListener(EbayHubEvent.ORDERS_CHECK_SUCCESS, onEbayHubEvent);
			main.ebayHub.events.removeEventListener(EbayHubEvent.ORDERS_CHECK_ERROR, onEbayHubEvent);
			
			if (e.type == EbayHubEvent.ORDERS_CHECK_SUCCESS) 
			{
				
				var resultMessage:String;
				
				if (e.storeNewEntries == 0)
					resultMessage = "Информация о заказах с Ибея в актуальном состоянии";
				else
					resultMessage = "Информация о заказах с Ибея обновлена: +" + e.storeNewEntries;
				
				infoPanel.showMessage(resultMessage, Colors.MESSAGE);
			}
			else if (e.type == EbayHubEvent.ORDERS_CHECK_ERROR) 
			{
				infoPanel.showMessage("Не вышло обновить информацию о заказах с Ибея", Colors.WARN);
			}
		}
		
		private function validateDecimalInput(e:TextEvent):void 
		{
			var numAllowedChars:RegExp = /[^\d\.,]/;
			
			if (e.text.search(numAllowedChars) != -1)
				e.preventDefault();
		}
		
		private function checkDecimalInputFormat(decimalNumberString:String):String 
		{
			var inputText:String = decimalNumberString;
			
			if ((main.numFrm.decimalSeparator == "," && inputText.indexOf(".") != -1) ||
				(main.numFrm.decimalSeparator == "." && inputText.indexOf(",") != -1))
			{
				inputText = inputText.replace(/\.|,/, main.numFrm.decimalSeparator);
				return inputText;
			}
			
			return inputText;
		}
		
		private function keyDown(e:KeyboardEvent):void
		{
			// ESC
			if (e.keyCode == Keyboard.ESCAPE)
			{
				if (main.settings.getKey(Settings.stayOnWindowClosing))
				{
					win.visible = false;
				}
				else
				{
					main.exitApp();
				}
			}
			
			else

			// F8
			if (e.keyCode == Keyboard.F8)
			{
				if (Capabilities.isDebugger)
				{
					infoPanel.showMessage("Проверка сообщения 1");
					infoPanel.showMessage("Проверка сообщения 2. Длиннее");
					infoPanel.showMessage("Проверка 3");
					infoPanel.showMessage("Проверка 3");
					infoPanel.showMessage("Пацан к успеху пришёл", Colors.SUCCESS);
					infoPanel.showMessage("Последнее китайское предупреждение", Colors.WARN);
					infoPanel.showMessage("Ошибочка!", Colors.BAD);
				}
			}
			
			else
			
			// F7
			if (e.keyCode == Keyboard.F7 && Capabilities.isDebugger)
			{
				main.charuStackMode.toggleMode();
			}
		}

		private function initWindowAndTray():void
		{
			win = stage.nativeWindow;
			win.title = "Quantum";
			
			var winPosStr:String = main.settings.getKey(Settings.winPos);
			var reResult:Array = winPosStr.match(/(-?\d+):(-?\d+)/);
			win.x = Number(reResult[1]);
			win.y = Number(reResult[2]);
			
			win.addEventListener(NativeWindowBoundsEvent.MOVE, function(e:NativeWindowBoundsEvent):void
			{
				main.settings.setKey(Settings.winPos, win.x + ":" + win.y);
			});
			
			win.addEventListener(Event.CLOSING, function(e:Event):void
			{
				e.preventDefault();
				if (main.settings.getKey(Settings.stayOnWindowClosing))
				{
					win.visible = false;
				}
				else
				{
					main.exitApp();
				}
			});
			
			main.trayMgr.addEventListener("mainWindowCall", function(e:Event):void
			{
				win.activate();
			});
			
			main.trayMgr.addEventListener("trayIconClick", function(e:Event):void
			{
				win.visible = !win.visible;
				if (win.visible) NativeApplication.nativeApplication.activate(win);
			});
			
			main.trayMgr.addEventListener("exitCall", function(e:Event):void
			{
				main.exitApp();
			});
			
			if (!main.settings.getKey(Settings.startInTray))
			{
				win.activate();
			}
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function activateWindow():void
		{
			if (!isVisible) win.visible = true;
			NativeApplication.nativeApplication.activate(win);
		}
		
		public function updateUiElement(elmID:String, val:*):void
		{
			switch (elmID)
			{
				case "selItemCount": 
					ui.nsCount.value = val;
					break;
				
				case "selItemTypeNotes": 
					ui.taDetails.text = val;
					break;
					
				case "selItemProductPrice":
					ui.tiPrice.text = (val == 0 ? "" : main.numFrm.formatNumber(val));
					break;
				
				case "selItemProductWeight":
					ui.tiWeight.text = (val == 0 ? "" : main.numFrm.formatNumber(val));
					break;	
					
				case "selItemProductSKU":
					ui.tiSku.text = val;
					break;
			}
		}
		
		public function focusAdrTextArea(act:Boolean = true):void
		{
			if (!act)
			{
				stage.focus = null;
				return;
			}
			
			stage.focus = ui.taAdr;
		}
		
		/**
		 * Paints an HTML-text to hex-color (Format: #000000) and returns HTML-formatted string
		 * @param color Hex-color of paint (Format: #000000)
		 * @param tx Text to be painted
		 * @return HTML-formatted string
		 */
		public function colorText(color:String, tx:String):String
		{
			return "<font color=\"" + color + "\">" + tx + "</font>";
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		/**
		 * Открыто ли окно структуры в системе
		 */
		public function get isVisible():Boolean
		{
			return win.visible;
		}
		
		public function get grpTitleTextInput():BigTextInput
		{
			return $grpTitleTextInput;
		}
		
		public function get ebayOrdersCheckButton():EbayOrdersCheckButton
		{
			return $ebayOrdersCheckButton;
		}
		
		public function get tableDataComposer():TableDataComposer
		{
			return $tableDataComposer;
		}
		
		public function get hintMgr():HintMgr
		{
			return $hintMgr;
		}
		
		public function get grpCnt():GroupsGim
		{
			return $grpCnt;
		}
		
		public function get infoPanel():QnInfoPanel
		{
			return $infoPanel;
		}
		
		public function get productsMgr():ProductsMgr 
		{
			return $productsMgr;
		}
	}
}