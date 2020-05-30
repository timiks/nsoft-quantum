package quantum.gui.modules 
{
	import fl.core.UIComponent;
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import quantum.Main;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayGim extends Sprite 
	{
		private var main:Main;
		
		private var win:NativeWindow;
		private var inited:Boolean = false;
		private var uiCmpList:Vector.<UIComponent>;
		
		private var topBar:Sprite;
		private var contentCnt:Sprite;
		
		public function EbayGim():void {}
		
		public function init():void
		{
			main = Main.ins;
			
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
			
			win = new NativeWindow(winOpts);
			win.stage.scaleMode = StageScaleMode.NO_SCALE;
			win.stage.align = StageAlign.TOP_LEFT;
			win.stage.stageWidth = 550;
			win.stage.stageHeight = 500;
			win.title = "Конфигурация eBay";
			
			win.stage.addChild(this);
			
			win.addEventListener(Event.CLOSING, function(e:Event):void
			{
				e.preventDefault();
				win.visible = false;
			});
			
			/**
			 * State visual composition
			 * ================================================================================
			 */
			
			// Top bar
			topBar = new Sprite();
			
			// Top bar → Top background plate
			var bgPlate:Shape = new Shape();
			bgPlate.graphics.beginFill(0xF9F9F9);
			bgPlate.graphics.drawRect(0, 0, stage.stageWidth, 40);
			bgPlate.graphics.endFill();
			bgPlate.graphics.lineStyle(1, 0xB7BABC);
			bgPlate.graphics.moveTo(0, 40);
			bgPlate.graphics.lineTo(stage.stageWidth, 40);
			topBar.addChild(bgPlate);
			
			// Top bar → Caption title
			var captionTitle:TextField = new TextField();
			captionTitle.defaultTextFormat = new TextFormat("Tahoma", 16, 0);
			captionTitle.embedFonts = false;
			captionTitle.autoSize = TextFieldAutoSize.LEFT;
			captionTitle.text = "Конфигурация eBay";
			captionTitle.x = 20;
			captionTitle.y = (topBar.height / 2) - (captionTitle.height / 2);
			topBar.addChild(captionTitle);
			
			// Content container
			contentCnt = new Sprite();
			
			//var uiPlate:StSettingsComponents = new StSettingsComponents();
			//contentCnt.addChild(uiPlate);
			//
			//uiCmpList = new Vector.<UIComponent>();
			//uiCmpList.push(uiPlate.cbStartInTray);
			//uiCmpList.push(uiPlate.cbStayOnWindowClosing);
			//uiCmpList.push(uiPlate.cbDeleteEmptyGroupsOnStartup);
			//uiCmpList.push(uiPlate.lblWh);
			//uiCmpList.push(uiPlate.selDefWarehouse);
			//uiCmpList.push(uiPlate.selDefWarehouse.textField);
			//uiCmpList.push(uiPlate.selDefWarehouse.dropdown);
			//uiCmpList.push(uiPlate.cbBackupOn);
			//uiCmpList.push(uiPlate.cbBackupImg);
			//uiCmpList.push(uiPlate.cbBackupCleanup);
			//uiCmpList.push(uiPlate.cbMoveDeletedItemsToUntitledGroup);
			//uiCmpList.push(uiPlate.cbDimUntitledGroupButton);
			//uiCmpList.push(uiPlate.cbAdrPrcPassAdrsForCanton);
			//uiCmpList.push(uiPlate.cbPaintColorForGroups);
			//uiCmpList.push(uiPlate.lblBuInt);
			//uiCmpList.push(uiPlate.selBackupInterval);
			//uiCmpList.push(uiPlate.selBackupInterval.textField);
			//uiCmpList.push(uiPlate.selBackupInterval.dropdown);
			
			// Style
			//var uim:UIComponentsMgr = main.uiCmpMgr;
			//var uiCmp:UIComponent;
			//for each (uiCmp in uiCmpList)
			//{
				//uim.setStyle(uiCmp);
			//}
			
			// Main display order
			addChild(topBar);
			addChild(contentCnt);
			
			/**
			 * UI functionality
			 * ================================================================================
			 */
			
			//function setupCheckbox(cb:CheckBox, setting:String):void
			//{
				//cb.selected = main.settings.getKey(setting);
				//cb.addEventListener("change", function(e:Event):void
				//{
					//main.settings.setKey(setting, cb.selected);
				//});
			//}
			//
			//function setupSelect(sel:ComboBox, setting:String, itemsList:Vector.<Object>):void
			//{
				//for each (var itm:Object in itemsList)
				//{
					//sel.addItem(itm);
				//}
				//
				//sel.addEventListener("change", function(e:Event):void
				//{
					//var currentItem:Object = sel.getItemAt(sel.selectedIndex);
					//main.settings.setKey(setting, currentItem.data);
				//});
				//
				//var selItem:Object;
				//var settingValue:String = main.settings.getKey(setting);
				//for (var i:int = 0; i < sel.length; i++)
				//{
					//selItem = sel.getItemAt(i);
					//if (selItem.data == settingValue)
					//{
						//sel.selectedIndex = i;
						//break;
					//}
					//
					//// If last iteration and no corresp. item found
					//if (i == sel.length-1)
					//{
						//// Auto set default: to the first item
						//sel.selectedIndex = 0;
						//
						//// Incorporate the change in settings
						//main.settings.setKey(setting,
							//sel.getItemAt(sel.selectedIndex).data); 
					//}
				//}
			//}
			//
			//for each (uiCmp in uiCmpList)
			//{
				//uiCmp.tabEnabled = false;
			//}
			
			
			// ================================================================================
			
			inited = true;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function showWindow(act:Boolean):void
		{
			if (!inited) init();
			
			if (act == true)
			{
				if (!isVisible)
				{
					win.x = (Capabilities.screenResolutionX / 2) - (win.width / 2);
					win.y = (Capabilities.screenResolutionY / 2) - (win.height / 2);
					win.visible = true;
				}
				
				NativeApplication.nativeApplication.activate(win);
			}
			
			else
			{
				win.visible = false;
				
				if (main.qnMgrGim.stage.nativeWindow.visible)
					main.qnMgrGim.stage.nativeWindow.activate();
			}
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get isVisible():Boolean
		{
			return win.visible;
		}
	}
}