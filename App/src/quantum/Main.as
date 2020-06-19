package quantum
{
	import flash.desktop.Clipboard;
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.globalization.LocaleID;
	import flash.globalization.NumberFormatter;
	import flash.system.Capabilities;
	import quantum.adr.AdrBgProcessor;
	import quantum.adr.AdrFormatMgr;
	import quantum.adr.processing.AdrPrcEngine;
	import quantum.backup.BackupMaster;
	import quantum.data.DataMgr;
	import quantum.ebay.EbayHubController;
	import quantum.ebay.EbayOrdersRegistry;
	import quantum.gui.GraphicsLibMgr;
	import quantum.gui.TrayMgr;
	import quantum.gui.UIComponentsMgr;
	import quantum.gui.modules.EbayGim;
	import quantum.gui.modules.SysErrorGim;
	import quantum.gui.modules.AddressyUiGim;
	import quantum.gui.modules.QnManagerGim;
	import quantum.gui.modules.SettingsGim;
	import quantum.jobs.CharuStackController;
	
	/**
	 * Quantum Application Main Module (CEM — Chief Executive Module)
	 * @author Tim Yusupov
	 */
	public class Main extends Sprite
	{
		private static var $ins:Main;
		
		// App Version
		private const $version:int 					= 6;
		private const $versionService:int 			= 1;
		private const $betaVersionNumber:int        = 0;
		
		private const $betaVersion:Boolean 			= Boolean(0);
		private const $futureVersion:Boolean 		= Boolean(0);
		private const bugs:Boolean 					= Boolean(0);
		
		// Modules
		// · Common
		private var $settings:Settings;
		private var $dataMgr:DataMgr;
		private var $trayMgr:TrayMgr;
		private var $soundMgr:SoundMgr;
		private var $backupMst:BackupMaster;
		private var $numFrm:NumberFormatter;
		private var $clipboardSvc:ClipboardSvc;
		
		// · Addressy
		private var $adrPrcEng:AdrPrcEngine;
		private var $adrBgProcessor:AdrBgProcessor;
		private var $adrFormatMgr:AdrFormatMgr;
		
		// · Ebay
		private var $ebayHub:EbayHubController;
		private var $ebayOrders:EbayOrdersRegistry;
		
		// · Jobs
		private var $charuStackMode:CharuStackController;
		
		// · UI
		private var $graphicsLibMgr:GraphicsLibMgr;
		private var $uiCmpMgr:UIComponentsMgr;
		private var $qnMgrGim:QnManagerGim;
		private var $adrUiGim:AddressyUiGim;
		private var $settingsGim:SettingsGim;
		private var $sysErrorGim:SysErrorGim;
		private var $ebayGim:EbayGim;
		
		private var $inited:Boolean;
		private var $exiting:Boolean;
		private var args:Array;
		
		public function Main():void
		{
			args = [];
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, appInvoke);
		}
		
		private function appInvoke(e:InvokeEvent):void
		{
			args = e.arguments;
			
			if ($inited)
			{
				if (args[0] == "/toggleBgPrc")
				{
					var val:Boolean = settings.getKey(Settings.bgClipboardProcessing);
					settings.setKey(Settings.bgClipboardProcessing, !val);
				}
				
				else
				
				if (args[0] == "/toggleCharuStackMode1")
				{
					charuStackMode.toggleMode();
				}
				
				else
				
				if (args[0] == "/showWindow")
				{
					qnMgrGim.activateWindow();
				}
				
				else
						
				if (args[0] == "/showAdrWindow")
				{
					adrUiGim.showWindow(true);
				}
				
				return;
			}
			
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			$ins = this;
			
			// Initialization of global error (exceptions) registration
			// It should be created very first
			if (!Capabilities.isDebugger) 
			{
				$sysErrorGim = new SysErrorGim();
				loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onSystemError);
			}
			
			/**
			 * General initialization
			 * ================================================================================
			 */
			
			// Number formatter
			$numFrm = new NumberFormatter(LocaleID.DEFAULT);
			$numFrm.fractionalDigits = 3;
			$numFrm.leadingZero = true;
			$numFrm.trailingZeros = false;
			$numFrm.useGrouping = false;
			 
			// Settings
			$settings = new Settings();
			$settings.load();
			
			// Data
			$dataMgr = new DataMgr();
			$dataMgr.load();
			
			// Backup Master
			$backupMst = new BackupMaster();
			
			// Ebay Hub Controller
			$ebayHub = new EbayHubController();
			$ebayHub.init();
			
			// Ebay Orders Registry
			$ebayOrders = new EbayOrdersRegistry();
			$ebayOrders.init();
			
			// Clipboard Service
			$clipboardSvc = new ClipboardSvc();
			$clipboardSvc.init();
			
			// Job › CharuStackMode
			$charuStackMode = new CharuStackController();
			$charuStackMode.init();
			
			// Tray
			$trayMgr = new TrayMgr();
			$trayMgr.initTray();
			
			// Sound
			$soundMgr = new SoundMgr();
			
			// Addressy's Processing Engine
			$adrPrcEng = new AdrPrcEngine();
			
			// Addressy's Format Manager
			$adrFormatMgr = new AdrFormatMgr();
			
			// Addressy's Background Processing Service
			$adrBgProcessor = new AdrBgProcessor();
			if (settings.getKey(Settings.bgClipboardProcessing))
				$adrBgProcessor.on();
			
			// UI Components Manager
			$uiCmpMgr = new UIComponentsMgr();
			
			// Graphics Lib Manager
			$graphicsLibMgr = new GraphicsLibMgr();
			
			// Main UI module (Quantum Manager) [with Window — Main Window]
			$qnMgrGim = new QnManagerGim();
			addChild($qnMgrGim);
			
			// Addressy UI (UI module) [with Window]
			$adrUiGim = new AddressyUiGim();
			
			// Settings State (UI module) [with Window]
			$settingsGim = new SettingsGim();
			
			// Ebay Config (UI module) [with Window]
			$ebayGim = new EbayGim();
			
			$inited = true;
		}
		
		private function onSystemError(event:UncaughtErrorEvent):void 
		{
			logRed("SYSTEM ERROR");
			
			if (event.error is Error)
			{
				var e:Error = event.error as Error;
				sysErrorGim.showError(e.message);
			}
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function logRed(str:String):void
		{
			trace("3:" + str);
		}
		
		public function exitApp():void
		{
			$exiting = true;
			trace("");
			trace("App is terminating");
			NativeApplication.nativeApplication.dispatchEvent(new Event(Event.EXITING));
			settings.saveFile();
			dataMgr.saveFile();
			NativeApplication.nativeApplication.exit();
		}
		
		public function randomRangeInt(aLower:int, aUpper:int):int
		{
			return int(Math.random() * (aUpper - aLower + 1)) + aLower;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		/**
		 * @static
		 */
		public static function get ins():Main
		{
			if ($ins == null)
				throw new Error("Accessing Main while it isn't initialized");
			return $ins;
		}
		
		public function get version():String
		{
			/* Major version */
			var vr:String = String($version);
			/* Minor (service) version */
			vr += "." + String($versionService);
			/* Beta version */
			if ($betaVersion) vr += " β" + ($betaVersionNumber == 0 || $betaVersionNumber == 1 ? "" : String($betaVersionNumber));
			/* Future version mark */
			if (Capabilities.isDebugger && $futureVersion) vr += " F";
			return vr;
		}
		
		public function get appName():String
		{
			return "Quantum";
		}
		
		public function get inited():Boolean
		{
			return $inited;
		}
		
		public function get exiting():Boolean
		{
			return $exiting;
		}
		
		public function get isFutureVersion():Boolean
		{
			return $futureVersion;
		}
		
		public function get isBetaActive():Boolean
		{
			return $betaVersion;
		}
		
		// ================================================================================
		
		public function get settings():Settings
		{
			return $settings;
		}
		
		public function get dataMgr():DataMgr
		{
			return $dataMgr;
		}
		
		public function get trayMgr():TrayMgr
		{
			return $trayMgr;
		}
		
		/**
		 * Движок обработки Addressy
		 */
		public function get adrPrcEng():AdrPrcEngine
		{
			if ($adrPrcEng == null)
			{
				throw new Error("ProcessingEngine hasn't initialized yet");
				return null;
			}
			
			else
			{
				return $adrPrcEng;
			}
		}
		
		public function get adrFormatMgr():AdrFormatMgr
		{
			return $adrFormatMgr;
		}
		
		public function get adrBgProcessor():AdrBgProcessor
		{
			return $adrBgProcessor;
		}
		
		public function get adrUiGim():AddressyUiGim
		{
			return $adrUiGim;
		}
		
		public function get qnMgrGim():QnManagerGim
		{
			return $qnMgrGim;
		}
		
		public function get settingsGim():SettingsGim
		{
			return $settingsGim;
		}
		
		public function get sysErrorGim():SysErrorGim 
		{
			return $sysErrorGim;
		}
		
		public function get ebayGim():EbayGim 
		{
			return $ebayGim;
		}
		
		public function get ebayHub():EbayHubController
		{
			return $ebayHub;
		}
		
		public function get ebayOrders():EbayOrdersRegistry
		{
			return $ebayOrders;
		}
		
		public function get uiCmpMgr():UIComponentsMgr
		{
			return $uiCmpMgr;
		}
		
		public function get soundMgr():SoundMgr
		{
			return $soundMgr;
		}
		
		public function get backupMst():BackupMaster
		{
			return $backupMst;
		}
		
		public function get numFrm():NumberFormatter 
		{
			return $numFrm;
		}
		
		public function get clipboardSvc():ClipboardSvc 
		{
			return $clipboardSvc;
		}
		
		public function get charuStackMode():CharuStackController 
		{
			return $charuStackMode;
		}
		
		public function get graphicsLibMgr():GraphicsLibMgr 
		{
			return $graphicsLibMgr;
		}
	}
}