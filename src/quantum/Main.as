package quantum
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.system.Capabilities;
	import quantum.backup.BackupMaster;
	import quantum.data.DataMgr;
	import quantum.gui.UIComponentsMgr;
	import quantum.states.StSettings;
	
	import quantum.adr.processing.ProcessingEngine;
	import quantum.adr.BgProcessor;
	import quantum.adr.FormatMgr;
	import quantum.states.StAddressyUI;
	import quantum.states.StQuantumManager;
	
	/**
	* Quantum Application Main Class
	* @author Tim Yusupov
	*/
	public class Main extends Sprite
	{
		private static var $ins:Main;
		
		// App Version
		private const $version:int 					= 5;
		private const $versionService:int 			= 0;
		private const $betaVersion:Boolean 			= false;
		private const $futureVersion:Boolean 		= true;
		private const bugs:Boolean 					= false;
		
		// Functional Members (Modules)
		// Common
		private var $settings:Settings;
		private var $dataMgr:DataMgr;
		private var $trayMgr:TrayMgr;
		private var $uiCmpMgr:UIComponentsMgr;
		private var $soundMgr:SoundMgr;
		private var $backupMst:BackupMaster;
		
		// Addressy
		private var $prcEng:ProcessingEngine;
		private var $bgProcessor:BgProcessor;
		private var $formatMgr:FormatMgr;
		
		// States
		private var $stQuantumMgr:StQuantumManager;
		private var $stAddressyUI:StAddressyUI;
		private var $stSettings:StSettings;
		
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
			
			/**
			 * Initialization
			 * ================================================================================
			 */
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
			
			// Main State (Quantum Manager) [with Window — Initial Window]
			$stQuantumMgr = new StQuantumManager();
			addChild($stQuantumMgr);
			
			// Addressy UI State [with Window]
			$stAddressyUI = new StAddressyUI();
			
			// Settings State [with Window]
			$stSettings = new StSettings();
			
			// Addressy's Background Processing Service
			$bgProcessor = new BgProcessor();
			if (settings.getKey(Settings.bgClipboardProcessing))
			{
				$bgProcessor.on();
			}
			
			$inited = true;
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
			var vr:String = String($version); // Major version
			vr += "." + String($versionService); // Service version
			if (Capabilities.isDebugger && $futureVersion) vr += " F"; // Future version mark
			if ($betaVersion) vr += " β"; // Beta tag
			return vr;
		}
		
		public function get appName():String
		{
			return "Quantum";
		}
		
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
	}
}