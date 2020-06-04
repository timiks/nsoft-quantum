package quantum.gui
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ScreenMouseEvent;
	import quantum.Main;
	import quantum.Settings;
	import quantum.events.SettingEvent;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class TrayMgr extends EventDispatcher
	{
		[Embed(source = "../../../lib/app-icons/app-icon-16.png")]
		private var Icon16:Class;
		
		[Embed(source = "../../../lib/app-icons/app-icon-16-green.png")]
		private var Icon16Green:Class;
		
		[Embed(source = "../../../lib/app-icons/app-icon-16-blue.png")]
		private var Icon16Blue:Class;
		
		private var main:Main;
		private var trayIcon:SystemTrayIcon;
		private var trayMenu:NativeMenu;
		
		private var itemMainWindowCall:NativeMenuItem;
		private var itemAdrBgPrcSwitch:NativeMenuItem;
		//private var itemSoundSwitch:NativeMenuItem;
		private var itemExit:NativeMenuItem;
		
		private const bgPrcSwitchLabelOn:String = "Включить фоновую обработку адресов";
		private const bgPrcSwitchLabelOff:String = "Отключить фоновую обработку адресов";
		
		//private const soundSwitchLabelOn:String = "Включить звуки";
		//private const soundSwitchLabelOff:String = "Отключить звуки";
		
		private var ico16:Bitmap;
		private var ico16green:Bitmap;
		private var ico16blue:Bitmap;
		
		public function TrayMgr():void
		{
			main = Main.ins;
		}
		
		public function initTray():void
		{
			ico16 = new Icon16() as Bitmap;
			ico16green = new Icon16Green() as Bitmap;
			ico16blue = new Icon16Blue() as Bitmap;
			
			trayIcon = NativeApplication.nativeApplication.icon as SystemTrayIcon;
			trayIcon.tooltip = main.appName /* + " " + main.version*/;
			
			controlIconDisplay();
			
			/**
			 * Пункт меню: Главное окно
			 * ================================================================================
			 */
			itemMainWindowCall = new NativeMenuItem("Главное окно");
			itemMainWindowCall.addEventListener(Event.SELECT, function(e:Event):void
			{
				dispatchEvent(new Event("mainWindowCall"));
			});
			
			/**
			 * Пункт меню: Переключатель фоновой обработки
			 * ================================================================================
			 */
			itemAdrBgPrcSwitch = new NativeMenuItem();
			
			var bgPrcSet:Boolean = main.settings.getKey(Settings.bgClipboardProcessing);
			if (bgPrcSet)
			{
				itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOff;
			}
			
			else
			{
				itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOn;
			}
			
			itemAdrBgPrcSwitch.addEventListener(Event.SELECT, function(e:Event):void
			{
				if (itemAdrBgPrcSwitch.label == bgPrcSwitchLabelOff)
				{
					itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOn;
					main.settings.setKey(Settings.bgClipboardProcessing, false);
				}
				
				else
				{
					itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOff;
					main.settings.setKey(Settings.bgClipboardProcessing, true);
				}
			});
			
			main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onSettingChange);
			main.charuStackMode.events.addEventListener(Event.CHANGE, onCharuStackModeUpdate);
			
			/**
			 * Пункт меню: Переключатель работы звуков
			 * ================================================================================
			 */
			//itemSoundSwitch = new NativeMenuItem("Звуки");
			
			/**
			 * Пункт меню: Выход
			 * ================================================================================
			 */
			itemExit = new NativeMenuItem("Выход");
			
			itemExit.addEventListener(Event.SELECT, function(e:Event):void
			{
				dispatchEvent(new Event("exitCall"));
			});
			
			/**
			 * Настройка меню
			 * ================================================================================
			 */
			trayMenu = new NativeMenu();
			trayMenu.addItem(itemMainWindowCall);
			trayMenu.addItem(itemAdrBgPrcSwitch);
			//trayMenu.addItem(itemSoundSwitch);
			trayMenu.addItem(itemExit);
			
			trayIcon.menu = trayMenu;
			
			// Tray Icon Click
			trayIcon.addEventListener(ScreenMouseEvent.CLICK, function(e:ScreenMouseEvent):void
			{
				dispatchEvent(new Event("trayIconClick"));
			});
		}
		
		private function controlIconDisplay():void 
		{
			if (main.charuStackMode.modeActive) 
			{
				// Charu stack job (mode)
				trayIcon.bitmaps = [ico16blue.bitmapData];
				return;
			}
			
			if (main.settings.getKey(Settings.bgClipboardProcessing))
			{
				// Addressy's background processing mode
				trayIcon.bitmaps = [ico16green.bitmapData];
				return;
			}
			
			else
			{
				// Default app icon
				trayIcon.bitmaps = [ico16.bitmapData];
			}
		}
		
		private function onCharuStackModeUpdate(e:Event):void 
		{
			controlIconDisplay();
		}
		
		private function onSettingChange(e:SettingEvent):void
		{
			if (e.settingName == Settings.bgClipboardProcessing)
			{
				// Пункт меню в трее
				if (e.newValue && itemAdrBgPrcSwitch.label == bgPrcSwitchLabelOn)
				{
					itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOff;
				}
				
				else if (!e.newValue && itemAdrBgPrcSwitch.label == bgPrcSwitchLabelOff)
				{
					itemAdrBgPrcSwitch.label = bgPrcSwitchLabelOn;
				}
				
				// Иконка
				controlIconDisplay();
			}
		}
	}
}