package quantum.ebay 
{
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import quantum.core.AppVars;
	import timicore.ChildProcessController;
	import timicore.communication.ProcessComProtocol;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayHubController 
	{
		private var childProcessCtrl:ChildProcessController;
		
		private var processFileDir:File;
		private const processFileName:String = "Quantum.EbayHub.exe";
		
		public function EbayHubController():void 
		{
			
		}
		
		public function init():void 
		{
			/*
			Алгоритм
			> Check process file presense
			> 
			> 
			*/
			
			processFileDir = File.applicationDirectory;
			
			childProcessCtrl =
				new ChildProcessController(processFileDir.resolvePath(processFileName).nativePath, onProcessOutput);
			childProcessCtrl.init();
			
			if (!childProcessCtrl.processFileIsOk)
				return;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs[0] = "run";
			processArgs[1] = Capabilities.isDebugger ? "adl" : AppVars.AppMainFileName;
			childProcessCtrl.startProcess(processArgs);
			
			// TEST
			var timer:Timer = new Timer(3000, 1);
			timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void 
			{
				trace("Tick!");
				//childProcessCtrl.testSendMessages();
				childProcessCtrl.sendMessagePlain(ProcessComProtocol.MsgCode_PlainMessage, "It's a plain message");
			});
			timer.start();
		}
		
		private function onProcessOutput(e:ProgressEvent):void 
		{
			trace("Output call, bytes available: " + childProcessCtrl.outputStream.bytesAvailable);
			var incomingMessage:String = childProcessCtrl.outputStream.readUTFBytes(childProcessCtrl.outputStream.bytesAvailable);
			trace(childProcessCtrl.parseComProtocolMessage(incomingMessage).data as String);
		}
	}
}