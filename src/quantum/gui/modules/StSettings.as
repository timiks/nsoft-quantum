package quantum.gui.modules
{
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import fl.core.UIComponent;
	import flash.desktop.NativeApplication;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import quantum.warehouse.WarehouseEntity;
	import quantum.gui.UIComponentsMgr;
	import quantum.Main;
	import quantum.Settings;
	import quantum.warehouse.Warehouse;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class StSettings extends Sprite
	{
		private var main:Main;
		private var st:Settings;
		
		private var win:NativeWindow;
		private var inited:Boolean = false;
		private var uiCmpList:Vector.<UIComponent>;
		
		private var topBar:Sprite;
		private var contentCnt:Sprite;
		
		public function StSettings():void {}
		
		public function init():void
		{
			main = Main.ins;
			st = main.settings;
			
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
			win.title = "Настройки Квантума";
			
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
			captionTitle.text = "Настройки";
			captionTitle.x = 20;
			captionTitle.y = (topBar.height / 2) - (captionTitle.height / 2);
			topBar.addChild(captionTitle);
			
			// Content container
			contentCnt = new Sprite();
			
			var uiPlate:StSettingsComponents = new StSettingsComponents();
			contentCnt.addChild(uiPlate);
			
			uiCmpList = new Vector.<UIComponent>();
			uiCmpList.push(uiPlate.cbStartInTray);
			uiCmpList.push(uiPlate.cbStayOnWindowClosing);
			uiCmpList.push(uiPlate.cbDeleteEmptyGroupsOnStartup);
			uiCmpList.push(uiPlate.lblWh);
			uiCmpList.push(uiPlate.selDefWarehouse);
			uiCmpList.push(uiPlate.selDefWarehouse.textField);
			uiCmpList.push(uiPlate.selDefWarehouse.dropdown);
			uiCmpList.push(uiPlate.cbBackupOn);
			uiCmpList.push(uiPlate.cbBackupImg);
			uiCmpList.push(uiPlate.cbBackupCleanup);
			uiCmpList.push(uiPlate.cbMoveDeletedItemsToUntitledGroup);
			uiCmpList.push(uiPlate.cbDimUntitledGroupButton);
			uiCmpList.push(uiPlate.cbAdrPrcPassAdrsForCanton);
			uiCmpList.push(uiPlate.lblBuInt);
			uiCmpList.push(uiPlate.selBackupInterval);
			uiCmpList.push(uiPlate.selBackupInterval.textField);
			uiCmpList.push(uiPlate.selBackupInterval.dropdown);
			
			// Style
			var uim:UIComponentsMgr = main.uiCmpMgr;
			var uiCmp:UIComponent;
			for each (uiCmp in uiCmpList)
			{
				uim.setStyle(uiCmp);
			}
			
			// Main display order
			addChild(topBar);
			addChild(contentCnt);
			
			/**
			 * UI functionality
			 * ================================================================================
			 */
			
			function setupCheckbox(cb:CheckBox, setting:String):void
			{
				cb.selected = main.settings.getKey(setting);
				cb.addEventListener("change", function(e:Event):void
				{
					main.settings.setKey(setting, cb.selected);
				});
			}
			
			function setupSelect(sel:ComboBox, setting:String, itemsList:Vector.<Object>):void
			{
				for each (var itm:Object in itemsList)
				{
					sel.addItem(itm);
				}
				
				sel.addEventListener("change", function(e:Event):void
				{
					var currentItem:Object = sel.getItemAt(sel.selectedIndex);
					main.settings.setKey(setting, currentItem.data);
				});
				
				var selItem:Object;
				var settingValue:String = main.settings.getKey(setting);
				for (var i:int = 0; i < sel.length; i++)
				{
					selItem = sel.getItemAt(i);
					if (selItem.data == settingValue)
					{
						sel.selectedIndex = i;
						break;
					}
				}
			}
			
			for each (uiCmp in uiCmpList)
			{
				uiCmp.tabEnabled = false;
			}
			
			// Checkboxes
			setupCheckbox(uiPlate.cbStartInTray, Settings.startInTray);
			setupCheckbox(uiPlate.cbStayOnWindowClosing, Settings.stayOnWindowClosing);
			setupCheckbox(uiPlate.cbDeleteEmptyGroupsOnStartup, Settings.deleteEmptyGroupsOnStartup);
			setupCheckbox(uiPlate.cbBackupOn, Settings.backupData);
			setupCheckbox(uiPlate.cbBackupImg, Settings.backupCreateImage);
			setupCheckbox(uiPlate.cbBackupCleanup, Settings.backupCleanup);
			setupCheckbox(uiPlate.cbMoveDeletedItemsToUntitledGroup, Settings.moveDeletedItemsToUntitledGroup);
			setupCheckbox(uiPlate.cbDimUntitledGroupButton, Settings.dimUntitledGroupButton);
			setupCheckbox(uiPlate.cbAdrPrcPassAdrsForCanton, Settings.adrPrcPassAdrsForCanton);
			
			// Selects (ComboBoxes)
			var selItems:Vector.<Object>;
			
			// Default warehouse
			selItems = new Vector.<Object>();
			for each (var whEnt:WarehouseEntity in Warehouse.entitiesList) 
			{
				selItems.push({label: whEnt.russianTitle, data: whEnt.ID});
			}
			setupSelect(uiPlate.selDefWarehouse, Settings.defaultWarehouse, selItems);
			uiPlate.selDefWarehouse.width += 150;
			
			// Backup interval
			selItems = new Vector.<Object>();
			selItems.push({label: "1 час", data: 60});
			selItems.push({label: "1.5 часа", data: 90});
			selItems.push({label: "2 часа", data: 120});
			selItems.push({label: "3 часа", data: 180});
			selItems.push({label: "4 часа", data: 240});
			selItems.push({label: "5 часов", data: 300});
			selItems.push({label: "6 часов", data: 360});
			selItems.push({label: "12 часов", data: 720});
			selItems.push({label: "1 день", data: 1440});
			selItems.push({label: "2 дня", data: 2880});
			selItems.push({label: "4 дня", data: 5760});
			selItems.push({label: "1 неделя", data: 10080});
			selItems.push({label: "2 недели", data: 20160});
			selItems.push({label: "1 месяц", data: 43200});
			setupSelect(uiPlate.selBackupInterval, Settings.backupInterval, selItems);
			
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
				
				if (main.stQuantumMgr.stage.nativeWindow.visible)
					main.stQuantumMgr.stage.nativeWindow.activate();
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