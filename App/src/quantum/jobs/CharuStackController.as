package quantum.jobs 
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import quantum.Main;
	import quantum.SoundMgr;
	import quantum.adr.processing.AdrPrcResult;
	import quantum.events.ClipboardEvent;
	import timicore.TimUtils;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class CharuStackController 
	{
		private var main:Main;
		private var $modeActive:Boolean;
		private var dataChunksBuffer:Vector.<String>;
		private var clipboardLastDataSaved:String;
		private var $events:EventDispatcher;
		
		// State info
		private var finishSoundMode:Boolean;
		
		public function CharuStackController():void 
		{
			
		}
		
		public function init():void 
		{
			main = Main.ins;
			$events = new EventDispatcher();
			dataChunksBuffer = new Vector.<String>();
		}
		
		public function toggleMode():void 
		{
			setModeActive(!$modeActive);
		}
		
		public function setModeActive(act:Boolean):void 
		{
			if (act == true && !$modeActive)
				modeSwitchInit();
			else
			if (act == false && $modeActive) 
				modeOff();
			
			events.dispatchEvent(new Event(Event.CHANGE));
				
			if (!finishSoundMode)
				main.soundMgr.play(SoundMgr.sndToggle);
			else 
				finishSoundMode = false;
		}
		
		private function modeSwitchInit():void 
		{
			main.clipboardSvc.clientAdd(this);
			main.clipboardSvc.events.addEventListener(ClipboardEvent.CHANGED, onClipboardChanged);
			
			while (dataChunksBuffer.length > 0) 
				dataChunksBuffer.pop();
			
			$modeActive = true;
			trace("Charu mode ON")
		}
		
		private function modeOff():void 
		{
			main.clipboardSvc.clientRemove(this);
			main.clipboardSvc.events.removeEventListener(ClipboardEvent.CHANGED, onClipboardChanged);
			
			while (dataChunksBuffer.length > 0) 
			{
				dataChunksBuffer.pop();
			}
			
			$modeActive = false;
			trace("Charu mode OFF")
		}
		
		private function onClipboardChanged(e:ClipboardEvent):void 
		{
			if (!Clipboard.generalClipboard.hasFormat(ClipboardFormats.TEXT_FORMAT))
				return;
					
			var cbCurrentData:String = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
			
			if ($modeActive)
				processClipboardChange(cbCurrentData);
		}
		
		private function processClipboardChange(newCbData:String):void 
		{
			var cbCurrentData:String = newCbData;
			
			cbCurrentData = TimUtils.trimSpaces(cbCurrentData);
			dataChunksBuffer.push(cbCurrentData);
			
			if (dataChunksBuffer.length < 2) 
			{
				main.soundMgr.play(SoundMgr.sndClick);
			}
			
			else if (dataChunksBuffer.length == 2) 
			{
				var mergedAddressSource:String =
					dataChunksBuffer[0] + "\n" +
					dataChunksBuffer[1];
					
				var prcResult:AdrPrcResult = main.adrPrcEng.process(mergedAddressSource);
				var finalMergedResult:String;
				
				if (prcResult.status == AdrPrcResult.STATUS_OK)
				{
					if (!prcResult.details.phoneNotFound) 
					{
						finalMergedResult = mergedAddressSource + "\n" + prcResult.resultObj.phone;
						finishSoundMode = true;
						main.soundMgr.play(SoundMgr.sndSuccess);
						Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, finalMergedResult);
					}
					else
					{
						operationFail("[Квантум: телефон не найден]");
					}
				}
				
				else
				{
					operationFail("[Квантум: не вышло обработать адрес]");
				}
					
				setModeActive(false);
			}
			
			// Safety belts
			else if (dataChunksBuffer.length > 2) 
			{
				setModeActive(false);
			}
		}
		
		private function operationFail(feedback:String):void 
		{
			finishSoundMode = true;
			main.soundMgr.play(SoundMgr.sndFail);
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, feedback);
		}
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
		
		public function get modeActive():Boolean 
		{
			return $modeActive;
		}
	}
}