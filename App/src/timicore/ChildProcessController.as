package timicore 
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.Socket;
	import flash.utils.IDataInput;
	import timicore.communication.ProcessComProtocol;
	import timicore.communication.ProcessComProtocolEvent;
	import timicore.communication.ProcessComProtocolMessage;
	import timicore.communication.ProcessEvent;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ChildProcessController 
	{
		private static const processRestartTries:int = 5;
		
		private var $events:EventDispatcher;
		
		private var process:NativeProcess;
		private var processFile:File;
		private var processOutputHandler:Function;
		private var processArguments:Vector.<String>; // Saved
		private var processRestartTriesCount:int = 0;
		
		private var comSocket:Socket;
		
		// State info
		private var processFileNotFound:Boolean = false;
		private var processIsOnDuty:Boolean = false;
		private var comSocketReady:Boolean = false;
		
		public function ChildProcessController(processFilePath:String, processOutputHandler:Function = null):void 
		{
			if (processFilePath == null)
				throw new Error("Process file path is null");
			
			processFile = new File(processFilePath);
			this.processOutputHandler = processOutputHandler;
			
			if (!processFile.exists)
			{
				trace("Process file not found");
				processFileNotFound = true;
				// [To-Do Here ↓]: throw error
			}
			else
			{
				
			}
		}
		
		public function init():void 
		{
			if (processFileNotFound)
				return;
			
			$events = new EventDispatcher();
				
			process = new NativeProcess();
			
			comSocket = new Socket();
			comSocket.addEventListener(Event.CONNECT, onComSocketConnected);
			comSocket.addEventListener(IOErrorEvent.IO_ERROR, onComSocketError);
		}
		
		public function dismiss():void 
		{
			process = null;
			
			comSocket.removeEventListener(Event.CONNECT, onComSocketConnected);
			comSocket.removeEventListener(IOErrorEvent.IO_ERROR, onComSocketError);
			comSocket = null
		}
		
		public function startProcess(args:Vector.<String> = null):void 
		{
			if (processFileNotFound)
			{
				trace("Process file not found. Can't start process!");
				return;
			}
			
			if (process.running)
				return;
			
			var processStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			
			processStartupInfo.executable = processFile;
			processStartupInfo.workingDirectory = File.applicationDirectory;
			
			// Possible arguments for process
			if (args != null)
			{
				processArguments = args; // Update if new
				processStartupInfo.arguments = args;
			}
			
			if (processOutputHandler != null)
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, processOutputHandler);
					
			process.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			
			//process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
			//process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onOutputError);
			//process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, onAppExit);
			
			process.start(processStartupInfo);
			processIsOnDuty = true;
		}
		
		public function terminateProcess():void 
		{
			if (!process.running)
				return;
			
			resetRunningState();
			process.exit();
		}
		
		public function sendMessageSignal(msgCode:int):void 
		{
			sendMessage(msgCode, ProcessComProtocol.MsgType_Signal);
		}
		
		public function sendMessagePlain(msgCode:int, msgStr:String):void 
		{
			sendMessage(msgCode, ProcessComProtocol.MsgType_Plain, msgStr);
		}
		
		public function sendMessageJSON(msgCode:int, msgDataOb:Object):void 
		{
			sendMessage(msgCode, ProcessComProtocol.MsgType_JSON, msgDataOb);
		}
		
		public function parseComProtocolMessage(rawSource:String):ProcessComProtocolMessage 
		{
			if (rawSource.length == 0)
				return null;
			
			// Remove 'end of message' sign in the end of the raw message
			if (rawSource.charAt(rawSource.length) == ProcessComProtocol.EndOfMessageSign)
				rawSource = rawSource.slice(0, rawSource.indexOf(ProcessComProtocol.EndOfMessageSign));
			
			var msgComponents:Array = rawSource.split(ProcessComProtocol.DataSeparator);
			
			var msgCode:int = parseInt(msgComponents[0]);
			var msgTypeCode:int = parseInt(msgComponents[1]);
			var msgData:Object = null;
			
			if (msgTypeCode != ProcessComProtocol.MsgType_Signal) 
				msgData = msgComponents[2] as String;
				
			if (msgTypeCode == ProcessComProtocol.MsgType_JSON) 
			{
				var msgDataOb:Object = JSON.parse(msgData as String)
				msgData = msgDataOb;
			}
			
			return new ProcessComProtocolMessage(msgCode, msgTypeCode, msgData);
		}
		
		private function resetRunningState():void 
		{
			processIsOnDuty = false;
			
			process.removeEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
			process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onProcessOutput);
			
			if (processOutputHandler != null)
				process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, processOutputHandler);
				
			// Com socket
			if (comSocket != null && comSocket.connected)
				comSocket.close();
			
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, onAppExit);
		}
		
		private function connectComSocket(port:int):void 
		{
			comSocket.connect("localhost", port);
		}
		
		private function onComSocketError(e:IOErrorEvent):void 
		{
			events.dispatchEvent(new ProcessEvent(ProcessEvent.COMMUNICATION_ERROR));
		}
		
		private function onComSocketConnected(e:Event):void 
		{
			trace("Com socket connected!");
			comSocketReady = true;
		}
		
		private function sendMessage(msgCode:int, msgTypeCode:int, msgDataPayload:Object = null):void 
		{
			if (!comSocketReady)
				return;
			
			// Encode message accord. protocol
			var encodedMsg:String = 
				msgCode.toString() + ProcessComProtocol.DataSeparator +
				msgTypeCode.toString() + ProcessComProtocol.DataSeparator;
			
			if (msgTypeCode == ProcessComProtocol.MsgType_Plain)
			{
				encodedMsg += msgDataPayload as String;
			}
			
			else
			
			if (msgTypeCode == ProcessComProtocol.MsgType_JSON)
			{
				encodedMsg += JSON.stringify(msgDataPayload);
			}
			
			encodedMsg += ProcessComProtocol.EndOfMessageSign;
			
			comSocket.writeUTFBytes(encodedMsg);
			comSocket.flush();
		}
		
		private function onComMessageReceived(msg:ProcessComProtocolMessage):void 
		{
			// Invalid message
			if (msg == null)
				return;
			
			if (msg.code == ProcessComProtocol.MsgCode_ComSocketReady)
			{
				connectComSocket(msg.data.socketServerPort);
			}
		}
		
		private function onProcessOutput(e:ProgressEvent):void 
		{
			var rawOutput:String = outputStream.readUTFBytes(outputStream.bytesAvailable);
			var rawMessages:Vector.<String> = new Vector.<String>();
			
			while (rawOutput.indexOf(ProcessComProtocol.EndOfMessageSign) != -1) 
			{
				rawMessages.push(rawOutput.slice(0, rawOutput.indexOf(ProcessComProtocol.EndOfMessageSign)));
				rawOutput = rawOutput.slice(rawOutput.indexOf(ProcessComProtocol.EndOfMessageSign)+1, rawOutput.length);
			}
			
			if (rawMessages.length > 0) 
			{
				var msg:ProcessComProtocolMessage;
				for each (var rawMsg:String in rawMessages) 
				{
					msg = parseComProtocolMessage(rawMsg);
					
					if (msg != null)
					{
						onComMessageReceived(msg);
						events.dispatchEvent(new ProcessComProtocolEvent(ProcessComProtocolEvent.COM_MESSAGE_RECEIVED, msg));
					}
				}
			}
		}
		
		private function onProcessExit(e:NativeProcessExitEvent):void 
		{
			if (processIsOnDuty)
			{
				resetRunningState();
				
				if (processRestartTriesCount < processRestartTries)
				{ 
					startProcess(processArguments); // Restart with any saved arguments
					processRestartTriesCount++;
					trace("Process restart " + processRestartTriesCount);
				}
				else 
				{
					events.dispatchEvent(new ProcessEvent(ProcessEvent.RESTART_OVERFLOW));
				}
			}
		}
		
		private function onAppExit(e:Event):void 
		{
			terminateProcess();
		}
		
		// ================================================================================
		// PROPERTIES
		// ================================================================================
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
		
		public function get outputStream():IDataInput
		{
			return process.standardOutput;
		}
		
		public function get processFileIsOk():Boolean
		{
			return !processFileNotFound;
		}
	}
}