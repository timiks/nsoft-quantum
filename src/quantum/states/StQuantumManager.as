package quantum.states {

	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.NativeWindow;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeWindowBoundsEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import quantum.gui.BigTextInput;
	import quantum.gui.GroupsContainer;
	import quantum.gui.UIComponentsMgr;
	import quantum.Main;
	import quantum.Settings;
	import quantum.TableDataComposer;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class StQuantumManager extends Sprite {

		private var main:Main;
		private var ui:QnManagerComposition;
		private var win:NativeWindow;
		private var grpCnt:GroupsContainer;

		// Public modules
		private var $tableDataComposer:TableDataComposer;
		private var $grpTitleTextInput:BigTextInput;

		public function StQuantumManager():void {
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {

			removeEventListener(Event.ADDED_TO_STAGE, init);

			main = Main.ins;

			// Stage settings
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			// State visual composition
			ui = new QnManagerComposition();
			addChild(ui);

			// Window and Tray functionality
			initWindowAndTray();

			// Version
			ui.tfVer.text = main.version;

			/**
			 * UI functionality
			 * ================================================================================
			 */

			grpCnt = new GroupsContainer(this);
			ui.addChildAt(grpCnt, 0);

			// BUTTONS
			// Exit
			ui.btnExit.tabEnabled = false;
			ui.btnExit.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				main.exitApp();
			});

			// Addressy UI show
			ui.btnShowAdrUI.tabEnabled = false;
			ui.btnShowAdrUI.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {

				main.stAdrUI.showWindow(true);

			});

			// New group
			ui.btnNewGroup.tabEnabled = false;
			ui.btnNewGroup.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {

				grpCnt.addNewGroup();

			});

			var uicm:UIComponentsMgr = main.uiCmpMgr;
			uicm.setStyle(ui.taAdr);
			uicm.setStyle(ui.nsCount);
			uicm.setStyle(ui.nsCount.textField);
			uicm.setStyle(ui.tiDetails);

			// Table data composer
			tableDataComposer = new TableDataComposer(grpCnt, ui.taAdr);
			tableDataComposer.init();

			// Group title text input
			grpTitleTextInput = new BigTextInput();
			grpTitleTextInput.tf = ui.tiGrpTitle;
			grpTitleTextInput.init(this, grpCnt, ui.tfstripe);

			ui.nsCount.addEventListener("change", function(e:Event):void {
				grpCnt.updateUiElementData("selItemCount", ui.nsCount.value);
			});

			ui.tiDetails.addEventListener("change", function(e:Event):void {
				grpCnt.updateUiElementData("selItemDetails", ui.tiDetails.text);
			});

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

		}

		private function keyDown(e:KeyboardEvent):void {

			// ESC
			if (e.keyCode == Keyboard.ESCAPE) {

				if (main.settings.getKey(Settings.stayOnWindowClosing)) {

					win.visible = false;

				} else {

					main.exitApp();

				}

			}

			else

			// F8
			if (e.keyCode == Keyboard.F8) {
				if (grpCnt.stage != null) {
					ui.removeChild(grpCnt);
				} else {
					ui.addChild(grpCnt);
				}
			}

		}

		private function initWindowAndTray():void {

			win = stage.nativeWindow;
			win.title = "Quantum";

			var winPosStr:String = main.settings.getKey(Settings.winPos);
			var reResult:Array = winPosStr.match(/(\d+):(\d+)/);
			win.x = Number(reResult[1]);
			win.y = Number(reResult[2]);

			win.addEventListener(NativeWindowBoundsEvent.MOVE, function(e:NativeWindowBoundsEvent):void {
				main.settings.setKey(Settings.winPos, win.x + ":" + win.y);
			});

			win.addEventListener(Event.CLOSING, function(e:Event):void {
				e.preventDefault();
				if (main.settings.getKey(Settings.stayOnWindowClosing)) {
					win.visible = false;
				} else {
					main.exitApp();
				}
			});

			main.trayMgr.addEventListener("mainWindowCall", function(e:Event):void {
				win.activate();
			});

			main.trayMgr.addEventListener("trayIconClick", function(e:Event):void {
				win.visible = !win.visible;
				if (win.visible) NativeApplication.nativeApplication.activate(win);
			});

			main.trayMgr.addEventListener("exitCall", function(e:Event):void {
				main.exitApp();
			});

			if (!main.settings.getKey(Settings.startInTray)) {
				win.activate();
			}

		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function activateWindow():void {
			if (!isVisible) win.visible = true;
			NativeApplication.nativeApplication.activate(win);
		}

		public function updateUiElement(elmID:String, val:*):void {

			switch (elmID) {

				case "selItemCount":
					ui.nsCount.value = val;
					break;

				case "selItemDetails":
					ui.tiDetails.text = val;
					break;

			}

		}

		public function focusAdrTextArea(act:Boolean = true):void {

			if (!act) {
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
		public function get isVisible():Boolean {
			return win.visible;
		}

		public function get grpTitleTextInput():BigTextInput {
			return $grpTitleTextInput;
		}

		public function set grpTitleTextInput(value:BigTextInput):void {
			$grpTitleTextInput = value;
		}

		public function get tableDataComposer():TableDataComposer {
			return $tableDataComposer;
		}

		public function set tableDataComposer(value:TableDataComposer):void {
			$tableDataComposer = value;
		}

	}

}