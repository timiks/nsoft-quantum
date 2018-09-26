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
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import quantum.Main;
	import quantum.Settings;
	import quantum.TableDataComposer;
	import quantum.gui.BigTextInput;
	import quantum.gui.Colors;
	import quantum.gui.HintMgr;
	import quantum.gui.QnInfoPanel;
	import quantum.gui.UIComponentsMgr;
	import quantum.gui.modules.GroupsContainer;
	import quantum.product.ProductsMgr;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class StQuantumManager extends Sprite
	{
		private var main:Main;
		private var ui:QnManagerComposition;
		private var win:NativeWindow;
		private var hintsCnt:Sprite;
		
		// Public modules
		private var $grpCnt:GroupsContainer;
		private var $tableDataComposer:TableDataComposer;
		private var $grpTitleTextInput:BigTextInput;
		private var $hintMgr:HintMgr;
		private var $infoPanel:QnInfoPanel;
		private var $productsMgr:ProductsMgr;
		
		public function StQuantumManager():void
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
			//addChild(ui);
			
			// Window and Tray functionality
			initWindowAndTray();
			
			// App version label
			ui.tfVer.htmlText = main.isFutureVersion ? "<font color=\"" + Colors.PURPLE + "\">" + main.version + "</font>" : main.version;
			
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
				main.stAdrUI.showWindow(true);
			});
			
			// · Settings window show
			ui.btnSettings.tabEnabled = false;
			ui.btnSettings.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				main.stSettings.showWindow(true);
			});
			
			// · New group
			ui.btnNewGroup.tabEnabled = false;
			ui.btnNewGroup.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				grpCnt.addNewGroup();
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
						
			var numLimitedCharsRe:RegExp = new RegExp("\\d|" + "\\" + main.numFrm.decimalSeparator);
			
			function limitChars(e:TextEvent):void 
			{
				if (e.text.search(numLimitedCharsRe) == -1)
					e.preventDefault();
			}
			
			// · Price of product entry of selected item (text input) 
			ui.tiPrice.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductPrice", ui.tiPrice.text);
			});
			ui.tiPrice.textField.addEventListener(TextEvent.TEXT_INPUT, limitChars);
			
			// · Weight of product entry of selected item (text input)
			ui.tiWeight.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductWeight", ui.tiWeight.text);
			});
			ui.tiWeight.textField.addEventListener(TextEvent.TEXT_INPUT, limitChars);
			
			// · SKU of product entry of selected item (text input)
			ui.tiSku.addEventListener("change", function(e:Event):void 
			{
				grpCnt.updateUiElementData("selItemProductSKU", ui.tiSku.text);
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
			
			// Show whole composition after everything looks well
			addChild(ui);
			
			/**
			 * Sub modules (private & public)
			 * ================================================================================
			 */
			
			// Hints
			hintsCnt = new Sprite;
			addChildAt(hintsCnt, numChildren);
			$hintMgr = new HintMgr();
			$hintMgr.init(hintsCnt);
			
			hintMgr.registerHint(ui.nsCount, "Количество товара");
			hintMgr.registerHint(ui.taDetails, "Заметка");
			hintMgr.registerHint(ui.tiPrice, "Цена товара (в USD)");
			hintMgr.registerHint(ui.tiWeight, "Вес товара (в КГ)");
			hintMgr.registerHint(ui.tiSku, "Значение SKU");
			
			// Products manager
			$productsMgr = new ProductsMgr();
			$productsMgr.init();
			
			// Groups Container
			$grpCnt = new GroupsContainer(this);
			ui.addChildAt(grpCnt, 0);
			
			// Table data composer
			$tableDataComposer = new TableDataComposer(grpCnt, ui.taAdr);
			$tableDataComposer.init();
			
			// Group title text input
			$grpTitleTextInput = new BigTextInput();
			$grpTitleTextInput.tf = ui.tiGrpTitle;
			$grpTitleTextInput.init(this, grpCnt, ui.tfstripe);
			
			// Info panel
			$infoPanel = new QnInfoPanel(ui.infopanel);
			ui.infopanel.x = 20;
			ui.infopanel.y = stage.stageHeight - ui.infopanel.height - 20;
			$infoPanel.init();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
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
					infoPanel.showMessage("Пацан к успеху пришёл", Colors.SUCCESS);
					infoPanel.showMessage("Последнее китайское предупреждение", Colors.WARN);
					infoPanel.showMessage("Ошибочка!", Colors.BAD);
				}
			}
			
			else
			
			// F7
			if (e.keyCode == Keyboard.F7)
			{
				
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
					ui.tiPrice.text = main.numFrm.formatNumber(val);
					break;
				
				case "selItemProductWeight":
					ui.tiWeight.text = main.numFrm.formatNumber(val);
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
		
		public function get tableDataComposer():TableDataComposer
		{
			return $tableDataComposer;
		}
		
		public function get hintMgr():HintMgr
		{
			return $hintMgr;
		}
		
		public function get grpCnt():GroupsContainer
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