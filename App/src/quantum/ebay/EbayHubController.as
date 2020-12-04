package quantum.ebay 
{
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import quantum.communication.QnProcessComProtocol;
	import quantum.core.AppVars;
	import quantum.events.EbayHubEvent;
	import timicore.ChildProcessController;
	import timicore.communication.ProcessComProtocol;
	import timicore.communication.ProcessComProtocolEvent;
	import timicore.communication.ProcessComProtocolMessage;
	import timicore.communication.ProcessEvent;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayHubController 
	{
		private var childProcessCtrl:ChildProcessController;
		
		private var processFileDir:File;
		private const processFileName:String = "Quantum.EbayHub.exe";
		
		private var $events:EventDispatcher;
		private var $processFileNotFound:Boolean;
		
		public function EbayHubController():void 
		{
			
		}
		
		public function init():void 
		{
			$events = new EventDispatcher();
			
			processFileDir = File.applicationDirectory;
			
			childProcessCtrl =
				new ChildProcessController(processFileDir.resolvePath(processFileName));
			childProcessCtrl.init();
			
			if (!childProcessCtrl.processFileIsOk)
			{
				$processFileNotFound = true;
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.PROCESS_FILE_NOT_FOUND));
				return;
			}
			
			childProcessCtrl.events.addEventListener(ProcessComProtocolEvent.COM_MESSAGE_RECEIVED, onComMessageReceived);
			childProcessCtrl.events.addEventListener(ProcessEvent.RESTART_OVERFLOW, onProcessEvent);
			childProcessCtrl.events.addEventListener(ProcessEvent.COMMUNICATION_ERROR, onProcessEvent);
				
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs[0] = "run";
			processArgs[1] = Capabilities.isDebugger ? "adl" : AppVars.AppMainFileName;
			childProcessCtrl.startProcess(processArgs);
		}
		
		public function SendCheckSignal():void 
		{
			childProcessCtrl.sendMessageSignal(QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheck);
		}
		
		public function SendClearCacheSignal():void 
		{
			childProcessCtrl.sendMessageSignal(QnProcessComProtocol.MsgCode_ClearEbayOrdersCache);
		}
		
		public function SendFullCheckSignal():void 
		{
			childProcessCtrl.sendMessageSignal(QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheckFull);
		}
		
		private function onProcessEvent(e:ProcessEvent):void 
		{
			if (e.type == ProcessEvent.RESTART_OVERFLOW) 
			{
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.PROCESS_RESTART_OVERFLOW));
			}
			else if (e.type == ProcessEvent.COMMUNICATION_ERROR)
			{
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.PROCESS_COM_ERROR));
			}
		}
		
		private function onComMessageReceived(e:ProcessComProtocolEvent):void 
		{
			var msg:ProcessComProtocolMessage = e.receivedComMessage;
			
			if (msg.code == ProcessComProtocol.MsgCode_PlainMessage)
			{
				trace("Plain msg: " + msg.data as String);
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayOrdersCheckStarted) 
			{
				trace("Ebay orders check started");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_CHECK_START_CONFIRMATION_RECEIVED));
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayOrdersCheckSuccess)
			{
				trace("Ebay orders сheck success. New entries: " + msg.data.newEntriesCount);
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_CHECK_SUCCESS, parseInt(msg.data.newEntriesCount)));
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayOrdersCheckError)
			{
				trace("Ebay oders check error");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_CHECK_ERROR));
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayAuthTokenError)
			{
				trace("Ebay user auth token error");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.USER_AUTH_TOKEN_ERROR));
			}
			else if (msg.code == ProcessComProtocol.MsgCode_SysError)
			{
				trace("Child process system error");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.PROCESS_SYS_ERROR));
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayOrdersStoreUpdated)
			{
				trace("Ebay orders store updated (from ebay child process)");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_FILE_UPDATED));
			}
			else if (msg.code == QnProcessComProtocol.MsgCode_EbayOrdersCacheCleared)
			{
				trace("Ebay orders store cache cleared (from ebay child process)");
				events.dispatchEvent(new EbayHubEvent(EbayHubEvent.ORDERS_CACHE_CLEARED));
			}
		}
		
		public function get processFileNotFound():Boolean 
		{
			return $processFileNotFound;
		}
		
		public function get events():EventDispatcher
		{
			return $events;
		}
	}
}