package quantum 
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import quantum.core.AppVars;
	import quantum.events.ClipboardEvent;
	import timicore.ProcessManager;
	import timicore.communication.ProcessEvent;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ClipboardSvc extends ProcessManager
	{
		private const processFileName:String = "Quantum.ClipboardSvc.exe";
		private const cbChangedOutputValue:String = "1";
		
		private var defaultProcessArgs:Vector.<String>;
		private var outputEventFireCounter:int = 0;
		private var clients:Vector.<Object>;
		
		public function ClipboardSvc():void 
		{
			super(File.applicationDirectory.resolvePath(processFileName));
		}
		
		public override function init():void 
		{
			super.init();
			childProcessCtrl.noComInputMode = true;
			childProcessCtrl.rawOutputHandleMode = true;
			childProcessCtrl.processOutputRawDataHandler = onProcessOutputData;
			
			clients = new Vector.<Object>();
			
			defaultProcessArgs = new Vector.<String>();
			defaultProcessArgs[0] = "run";
			defaultProcessArgs[1] = Capabilities.isDebugger ? "adl" : AppVars.AppMainFileName;
			
			childProcessCtrl.events.addEventListener(ProcessEvent.RESTARTED, onProcessEvent);
			
			//childProcessCtrl.startProcess(defaultProcessArgs);
		}
		
		public function clientAdd(client:Object):void 
		{
			clients.push(client);
			controlLive();
		}
		
		public function clientRemove(client:Object):void 
		{
			var cidx:int = clients.indexOf(client);
			
			if (cidx == -1)
				return;
				
			// if found then ↓
			clients.splice(cidx, 1);
			
			controlLive();
		}
		
		private function controlLive():void 
		{
			if (clients.length > 0 && !childProcessCtrl.processIsActive) 
			{
				childProcessCtrl.startProcess(defaultProcessArgs);
			}
			
			else
			
			if (clients.length == 0 && childProcessCtrl.processIsActive) 
			{
				childProcessCtrl.terminateProcess();
				outputEventFireCounter = 0; // Reset
			}
		}
		
		private function onProcessEvent(e:ProcessEvent):void 
		{
			if (e.type == ProcessEvent.RESTARTED) 
			{
				outputEventFireCounter = 0;
			}
		}
		
		private function onProcessOutputData(rawInputStr:String):void 
		{
			if (outputEventFireCounter == 0)
			{
				outputEventFireCounter = 1;
				return;
			}
			
			if (rawInputStr == cbChangedOutputValue)
			{
				if (!Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
					return;
				
				events.dispatchEvent(new ClipboardEvent(ClipboardEvent.CHANGED));
				trace("Clipboard changed!");
			}
		}
	}
}