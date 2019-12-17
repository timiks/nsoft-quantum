package quantum
{
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.globalization.LocaleID;
	import flash.globalization.NumberFormatter;
	import flash.system.Capabilities;
	import quantum.adr.BgProcessor;
	import quantum.adr.FormatMgr;
	import quantum.adr.processing.ProcessingEngine;
	import quantum.backup.BackupMaster;
	import quantum.data.DataMgr;
	import quantum.gui.GraphicsLibMgr;
	import quantum.gui.UIComponentsMgr;
	import quantum.gui.modules.GimGlobalError;
	import quantum.gui.modules.StAddressyUI;
	import quantum.gui.modules.StQuantumManager;
	import quantum.gui.modules.StSettings;
	
	/**
	 * Quantum Application Main Module (CEM — Chief Executive Module)
	 * @author Tim Yusupov
	 */
	public class Main extends Sprite
	{
		private static var $ins:Main;
		
		// App Version
		private const $version:int 					= 5;
		private const $versionService:int 			= 10;
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
		
		// · Addressy
		private var $prcEng:ProcessingEngine;
		private var $bgProcessor:BgProcessor;
		private var $formatMgr:FormatMgr;
		
		// · UI
		private var $graphicsLibMgr:GraphicsLibMgr;
		private var $uiCmpMgr:UIComponentsMgr;
		private var $stQuantumMgr:StQuantumManager;
		private var $stAddressyUI:StAddressyUI;
		private var $stSettings:StSettings;
		private var $gimGlobalError:GimGlobalError;
		
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
					
				if (args[0] == "/showWindow")
				{
					stQuantumMgr.activateWindow();
				}
				
				else
						
				if (args[0] == "/showAdrWindow")
				{
					stAdrUI.showWindow(true);
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
				$gimGlobalError = new GimGlobalError();
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
			
			// Tray
			$trayMgr = new TrayMgr();
			$trayMgr.initTray();
			
			// Sound
			$soundMgr = new SoundMgr();
			
			// Addressy's Processing Engine
			$prcEng = new ProcessingEngine();
			
			// Addressy's Format Manager
			$formatMgr = new FormatMgr();
			
			// UI Components Manager
			$uiCmpMgr = new UIComponentsMgr();
			
			// Graphics Lib Manager
			$graphicsLibMgr = new GraphicsLibMgr();
			
			// Main UI module (Quantum Manager) [with Window — Main Window]
			$stQuantumMgr = new StQuantumManager();
			addChild($stQuantumMgr);
			
			// Addressy UI (UI module) [with Window]
			$stAddressyUI = new StAddressyUI();
			
			// Settings State (UI module) [with Window]
			$stSettings = new StSettings();
			
			// Addressy's Background Processing Service
			$bgProcessor = new BgProcessor();
			if (settings.getKey(Settings.bgClipboardProcessing))
			{
				$bgProcessor.on();
			}
			
			$inited = true;
		}
		
		private function onSystemError(event:UncaughtErrorEvent):void 
		{
			logRed("SYSTEM ERROR");
			
			if (event.error is Error)
			{
				var e:Error = event.error as Error;
				gimGlobalError.showError(e.message);
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
			if ($betaVersion) vr += " β" + String($betaVersionNumber);
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
		public function get prcEng():ProcessingEngine
		{
			if ($prcEng == null)
			{
				throw new Error("ProcessingEngine hasn't initialized yet");
				return null;
			}
			
			else
			{
				return $prcEng;
			}
		}
		
		public function get formatMgr():FormatMgr
		{
			return $formatMgr;
		}
		
		public function get bgProcessor():BgProcessor
		{
			return $bgProcessor;
		}
		
		public function get stAdrUI():StAddressyUI
		{
			return $stAddressyUI;
		}
		
		public function get stQuantumMgr():StQuantumManager
		{
			return $stQuantumMgr;
		}
		
		public function get stSettings():StSettings
		{
			return $stSettings;
		}
		
		public function get gimGlobalError():GimGlobalError 
		{
			return $gimGlobalError;
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
		
		public function get graphicsLibMgr():GraphicsLibMgr 
		{
			return $graphicsLibMgr;
		}
	}
}