package quantum.gui.elements 
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.SoundMgr;
	import quantum.gui.Colors;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class QnInfoPanel 
	{
		private var main:Main;
		
		private var $currentMessage:String;
		/* Last element in queue when queue is active, otherwise > empty */
		private var lastQueMessage:String;
		
		private var disOb:QuantumInfoPanel;
		private var tf:TextField;
		private var backRect:Rectangle;
		private var scaleFrame:Shape;
		
		private var msgQueue:Vector.<Object>;
		private var queTmr:Timer;
		private var blinkTimer:Timer;
		private var lastShowCallTime:Number = 0;
		
		public function QnInfoPanel(disOb:QuantumInfoPanel):void 
		{
			main = Main.ins;
			this.disOb = disOb;
			this.tf = disOb.ipo.tf as TextField;
		}
		
		public function init():void 
		{
			// Settings
			disOb.mouseEnabled = false;
			disOb.mouseChildren = false;
			
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.defaultTextFormat.kerning = true;
			
			backRect = new Rectangle();
			scaleFrame = new Shape();
			scaleFrame.filters = [new DropShadowFilter(1, 45, 0, 0.3, 4, 4, 1.5)];
			
			disOb.ipo.addChildAt(scaleFrame, 0);
			
			msgQueue = new Vector.<Object>();
			queTmr = new Timer(2500);
			
			blinkTimer = new Timer(500, 4);
			blinkTimer.addEventListener(TimerEvent.TIMER, blink);
			blinkTimer.addEventListener(TimerEvent.TIMER_COMPLETE, blinkComplete);
		}
		
		private function blink(e:TimerEvent):void 
		{
			disOb.visible = !disOb.visible;
		}
		
		private function blinkComplete(e:TimerEvent):void 
		{
			if (!disOb.visible)
				disOb.visible = true;
		}
		
		public function showMessage(text:String, color:String = null, priority:Boolean = false, queShow:Boolean = false):void
		{
			if (!priority && !queShow && (new Date().time - lastShowCallTime) < 1300 && disOb.isPlaying && $currentMessage != text)
			{
				if (lastQueMessage != text) 
				{
					// Put message on queue
					msgQueue.push({"text": text, "color": color});
					
					if (!queTmr.running)
					{
						queTmr.addEventListener(TimerEvent.TIMER, checkQueue);
						queTmr.start();
					}
					
					trace("Message is on queue:", text);
					lastQueMessage = text;
					return;
				}
				
				else
				{
					/* Don't put the same message on queue CONSECUTIVELY */
					return;
				}
			}
			
			lastShowCallTime = new Date().time;
			var noSound:Boolean = false;
			
			if (disOb.isPlaying && $currentMessage == text)
			{
				noSound = true;
				if (!blinkTimer.running)
				{
					blinkTimer.reset();
					blinkTimer.start();
				}
			}	
			
			if (disOb.isPlaying && $currentMessage == text && !queShow)
			{
				disOb.gotoAndPlay(10);
				return;
			}
			
			// ================================================================================
			
			var backColor:uint;
			switch (color) 
			{
				case Colors.BAD:
					backColor = 0xA20006; // Red
					break;
				case Colors.WARN:
					backColor = 0xC04400; // Orange
					break;
				case Colors.SUCCESS:
					backColor = 0x157F09; // Green
					break;
				case Colors.MESSAGE:
				default:
					backColor = 0x09457D; // Dark blue
					break;
			}
			
			tf.htmlText = main.qnMgrGim.colorText("#FFFFFF", text);
			
			backRect.width = tf.textWidth + 50;
			backRect.height = tf.textHeight + 4;
			
			tf.x = scaleFrame.x;
			tf.y = scaleFrame.y;
			
			scaleFrame.graphics.clear();
			scaleFrame.graphics.beginFill(backColor); // F9F9F9
			scaleFrame.graphics.drawRect(0, 0, backRect.width, backRect.height);
			scaleFrame.graphics.endFill();
			
			tf.width = scaleFrame.width;
			tf.height = scaleFrame.height;
			
			disOb.x = disOb.stage.stageWidth / 2 - disOb.width / 2;
			
			$currentMessage = text;
			trace("Message" + (queShow ? " (Queue)" : "") + " is being shown:", text);
			
			if (queShow) 
			{
				disOb.gotoAndPlay(2);
				return;
			}
			
			disOb.isPlaying ? disOb.gotoAndPlay(2) : disOb.gotoAndPlay(1);
			
			if (noSound) return;
			
			// Sound
			switch (color) 
			{
				case Colors.MESSAGE:
				case Colors.WARN:
				case null:
					main.soundMgr.play(SoundMgr.sndMessage);
					break;
				case Colors.BAD:
					main.soundMgr.play(SoundMgr.sndError);
					break;
			}
		}
		
		private function checkQueue(e:TimerEvent):void 
		{
			if (msgQueue.length > 0) 
			{
				var msgParams:Object = msgQueue.shift();
				showMessage(msgParams.text, msgParams.color, false, true);
			}
			
			else 
			{
				queTmr.stop();
				queTmr.reset();
				queTmr.removeEventListener(TimerEvent.TIMER, checkQueue);
				lastQueMessage = "";
				trace("Message queue has finished");
			}
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get currentMessage():String 
		{
			return $currentMessage;
		}
	}
}