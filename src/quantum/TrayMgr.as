package quantum
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
	import quantum.events.SettingEvent;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class TrayMgr extends EventDispatcher
	{
		[Embed(source = "/../lib/icons/adr-icon-16-bright.png")]
		private var Icon16:Class;
		
		[Embed(source = "/../lib/icons/adr-ico16-bgmode-green.png")]
		private var Icon16BgMode:Class;
		
		private var main:Main;
		private var trayIcon:SystemTrayIcon;
		private var trayMenu:NativeMenu;
		
		private var itemMainWindowCall:NativeMenuItem;
		private var itemBgPrcSwitch:NativeMenuItem;
		//private var itemSoundSwitch:NativeMenuItem;
		private var itemExit:NativeMenuItem;
		
		private const bgPrcSwitchLabelOn:String = "Включить фоновую обработку адресов";
		private const bgPrcSwitchLabelOff:String = "Отключить фоновую обработку адресов";
		
		//private const soundSwitchLabelOn:String = "Включить звуки";
		//private const soundSwitchLabelOff:String = "Отключить звуки";
		
		private var ico16:Bitmap;
		private var ico16BgMode:Bitmap;
		
		public function TrayMgr():void
		{
			main = Main.ins;
		}
		
		public function initTray():void
		{
			ico16 = new Icon16() as Bitmap;
			ico16BgMode = new Icon16BgMode() as Bitmap;
			
			trayIcon = NativeApplication.nativeApplication.icon as SystemTrayIcon;
			trayIcon.tooltip = main.appName /* + " " + main.version*/;
			
			// Иконка
			if (main.settings.getKey(Settings.bgClipboardProcessing))
			{
				trayIcon.bitmaps = [ico16BgMode.bitmapData];
			}
			
			else
			{
				trayIcon.bitmaps = [ico16.bitmapData];
			}
			
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
			itemBgPrcSwitch = new NativeMenuItem();
			
			var bgPrcSet:Boolean = main.settings.getKey(Settings.bgClipboardProcessing);
			if (bgPrcSet)
			{
				itemBgPrcSwitch.label = bgPrcSwitchLabelOff;
			}
			
			else
			{
				itemBgPrcSwitch.label = bgPrcSwitchLabelOn;
			}
			
			itemBgPrcSwitch.addEventListener(Event.SELECT, function(e:Event):void
			{
				if (itemBgPrcSwitch.label == bgPrcSwitchLabelOff)
				{
					itemBgPrcSwitch.label = bgPrcSwitchLabelOn;
					main.settings.setKey(Settings.bgClipboardProcessing, false);
				}
				
				else
				{
					itemBgPrcSwitch.label = bgPrcSwitchLabelOff;
					main.settings.setKey(Settings.bgClipboardProcessing, true);
				}
			});
			
			main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onSettingChange);
			
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
			trayMenu.addItem(itemBgPrcSwitch);
			//trayMenu.addItem(itemSoundSwitch);
			trayMenu.addItem(itemExit);
			
			trayIcon.menu = trayMenu;
			
			// Tray Icon Click
			trayIcon.addEventListener(ScreenMouseEvent.CLICK, function(e:ScreenMouseEvent):void
			{
				dispatchEvent(new Event("trayIconClick"));
			});
		}
		
		private function onSettingChange(e:SettingEvent):void
		{
			
			if (e.settingName == Settings.bgClipboardProcessing)
			{
				
				// Пункт меню в трее
				if (e.newValue && itemBgPrcSwitch.label == bgPrcSwitchLabelOn)
				{
					itemBgPrcSwitch.label = bgPrcSwitchLabelOff;
				}
				
				else if (!e.newValue && itemBgPrcSwitch.label == bgPrcSwitchLabelOff)
				{
					itemBgPrcSwitch.label = bgPrcSwitchLabelOn;
				}
				
				// Иконка
				if (e.newValue)
				{
					trayIcon.bitmaps = [ico16BgMode.bitmapData];
				}
				
				else if (!e.newValue)
				{
					trayIcon.bitmaps = [ico16.bitmapData];
				}
			}
		}
	}
}