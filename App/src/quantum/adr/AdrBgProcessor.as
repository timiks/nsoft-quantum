package quantum.adr
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.media.Sound;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import quantum.core.AppVars;
	import quantum.events.SettingEvent;
	import quantum.Settings;
	import quantum.SoundMgr;
	
	import quantum.adr.processing.AdrPrcResult;
	import quantum.Main;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class AdrBgProcessor
	{
		private var main:Main;
		private var serviceProcess:NativeProcess;
		private var serviceProcessFile:File;
		private var serviceProcessFileNotFound:Boolean = false;
		
		private const serviceProcessFileName:String = "AddressyService.exe";
		private const cbChangedOutputValue:String = "1";
		
		private var tmrDelay:Timer;
		
		public function AdrBgProcessor():void
		{
			main = Main.ins;
			main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onSettingChange);
			
			serviceProcessFile = File.applicationDirectory.resolvePath(serviceProcessFileName);
			
			if (!serviceProcessFile.exists)
			{
				main.logRed("Service Process File not found");
				serviceProcessFileNotFound = true;
				// [To-Do Here ↓]: Global Error
			} 
			else 
			{
				trace("Service Process File found: " + serviceProcessFile.nativePath);
				tmrDelay = new Timer(1300, 1);
			}
		}
		
		private function onSettingChange(e:SettingEvent):void
		{
			if (e.settingName == Settings.bgClipboardProcessing)
			{
				e.newValue == true ? main.logRed("BgProcessor ON") : main.logRed("BgProcessor OFF");
				
				if (e.newValue == true)
					on();
				else
					off();
				
				// Sound
				main.soundMgr.play(SoundMgr.sndBgPrcToggle);
			}
		}
		
		public function on():void
		{
			if (serviceProcessFileNotFound) 
				return;
				
			launchServiceProcess();
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, onExitApp);
		}
		
		public function off():void
		{
			if (serviceProcessFileNotFound) 
				return;
				
			closeServiceProcess();
			
			if (tmrDelay.running)
				tmrDelay.stop();
			
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, onExitApp);
		}
		
		private function launchServiceProcess():void
		{
			if (serviceProcess != null && serviceProcess.running)
				return;
			
			var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			processStartupInfo.executable = serviceProcessFile;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs[0] = "/run";
			processArgs[1] = Capabilities.isDebugger ? "adl" : AppVars.AppMainFileName;
			processStartupInfo.arguments = processArgs;
			
			serviceProcess = new NativeProcess();
			serviceProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			serviceProcess.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			
			serviceProcess.start(processStartupInfo);
		}
		
		private function closeServiceProcess():void
		{
			if (serviceProcess == null && !serviceProcess.running)
				return;
			
			serviceProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			serviceProcess.removeEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			serviceProcess.exit();
			serviceProcess = null;
		}

		private function onProcessOutput(e:ProgressEvent):void
		{
			var output:String = serviceProcess.standardOutput.readUTFBytes(serviceProcess.standardOutput.bytesAvailable);
			
			trace("");
			main.logRed("Output from Service Process: " + output + (output == cbChangedOutputValue ? " (Clipboard Changed)" : ""));
			
			if (output == cbChangedOutputValue)
			{
				if (tmrDelay.running)
					return;
				
				if (!Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
					return;
				
				trace("BgProcessor has called processing");
				processClipboard();
			}
		}
		
		private function onProcessExit(e:NativeProcessExitEvent):void
		{
			main.logRed("Service Process has exited with code " + e.exitCode);
			
			/*
			Алгоритм
			> if bgProcessing on and exited > relaunch
			*/
			if (main.settings.getKey(Settings.bgClipboardProcessing))
			{
				main.logRed("Сервис-процесс завершился несанкционированно. Перезапуск");
				launchServiceProcess();
			}
		}
		
		private function processClipboard():void
		{
			var clipboardText:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
			trace("CB IN:\n" + clipboardText);
			
			var prcResult:AdrPrcResult = main.adrPrcEng.process(clipboardText);
			var snd:Sound;
			
			/**
			 * SUCCESS
			 * ================================================================================
			 */
			if (prcResult.status == AdrPrcResult.STATUS_OK)
			{
				var currentFormat:String = main.settings.getKey(Settings.outputFormat);
				var formattedStr:String = main.adrFormatMgr.format(prcResult.resultObj, currentFormat);
				Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, formattedStr);
				trace("FRM OUT:\n" + formattedStr);

				/*var copyTimer:Timer = new Timer(50, 1);
				copyTimer.addEventListener(TimerEvent.TIMER, timeToCopy);
				copyTimer.start();

				function timeToCopy(e:TimerEvent):void {
					Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, formattedStr);
					copyTimer.removeEventListener(TimerEvent.TIMER, timeToCopy);

					// Sound
					snd = new sndOkClass() as Sound;
					snd.play();
				}*/

				// Timer
				tmrDelay.start();

				// Sound
				main.soundMgr.play(SoundMgr.sndSuccess);

				// Show result in Main Window if it's visible
				if (main.adrUiGim.isVisible)
					main.adrUiGim.showBgProcessingResult(prcResult.resultObj);
			}
			
			else

			/**
			 * ERROR
			 * ================================================================================
			 */
			if (prcResult.status == AdrPrcResult.STATUS_ERROR)
			{
				main.soundMgr.play(SoundMgr.sndError);
			}
		}
		
		private function onExitApp(e:Event):void
		{
			closeServiceProcess();
			trace("Service Process was closed due to App exiting");
		}
	}
}