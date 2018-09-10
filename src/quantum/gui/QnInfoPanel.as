package quantum.gui 
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.SoundMgr;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class QnInfoPanel 
	{
		private var main:Main;
		
		private var $currentMessage:String;
		
		private var $lastQueMessage:String;
		
		private var disOb:QuantumInfoPanel;
		private var tf:TextField;
		private var backRect:Rectangle;
		private var scaleFrame:Shape;
		
		private var msgQueue:Vector.<Object>;
		private var queTmr:Timer;
		
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
			
			backRect = new Rectangle();
			scaleFrame = new Shape();
			
			disOb.ipo.addChildAt(scaleFrame, 0);
			
			msgQueue = new Vector.<Object>();
			queTmr = new Timer(3000);
		}
		
		public function showMessage(text:String, color:String = null, queShow:Boolean = false):void
		{
			if (disOb.isPlaying && disOb.currentFrame < disOb.totalFrames - 8 &&
				$currentMessage != text && !queShow)
			{
				if ($lastQueMessage != text) 
				{
					// Put message on queue
					msgQueue.push({"text": text, "color": color});
					queTmr.addEventListener(TimerEvent.TIMER, checkQueue);
					queTmr.start();
					trace("Message is on queue:", text);
					$lastQueMessage = text;
					return;
				}
				else
				{
					return;
				}
			}
			
			//if (color == null) color = "#FFFFFF";
			
			var noSound:Boolean = false;
			
			if (disOb.isPlaying && $currentMessage == text) noSound = true;
			
			var backColor:uint;
			switch (color) 
			{
				case Colors.BAD:
					backColor = 0xA20006;
					break;
				case Colors.WARN:
					backColor = 0xA63B00;
					break;
				case Colors.SUCCESS:
					backColor = 0x157F09;
					break;
				case Colors.MESSAGE:
				default:
					backColor = 0x09457D; // Black
					break;
			}
			
			tf.htmlText = colorText("#FFFFFF", text);
			
			backRect.width = tf.textWidth + 50; // 7
			backRect.height = tf.textHeight + 4; // 4
			
			tf.x = scaleFrame.x;
			tf.y = scaleFrame.y;
			
			scaleFrame.graphics.clear();
			scaleFrame.graphics.beginFill(backColor); // F9F9F9
			scaleFrame.graphics.drawRect(0, 0, backRect.width, backRect.height);
			scaleFrame.graphics.endFill();
			
			scaleFrame.graphics.lineStyle(1, 0xB7BABC);
			scaleFrame.graphics.drawRect(0, 0, backRect.width, backRect.height);
			
			tf.width = scaleFrame.width;
			tf.height = scaleFrame.height;
			
			$currentMessage = text;
			trace("Message" + (queShow ? " (Queue)" : "") + " is being shown:", text);
			
			if (queShow) 
			{
				disOb.gotoAndPlay(2);
				return;
			}
			
			if ((disOb as MovieClip).isPlaying)
			{
				disOb.gotoAndPlay(10);
			} 
			
			else
			{
				disOb.gotoAndPlay(1);
			}
			
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
					main.soundMgr.play(SoundMgr.sndPrcError);
					break;
			}
		}
		
		private function checkQueue(e:TimerEvent):void 
		{
			if (msgQueue.length > 0) 
			{
				var msgParams:Object = msgQueue.shift();
				showMessage(msgParams.text, msgParams.color, true);
			}
			else 
			{
				queTmr.stop();
				queTmr.removeEventListener(TimerEvent.TIMER, checkQueue);
				trace("Message queue has finished");
			}
		}
		
		/**
		 * Paints an HTML-text to hex-color (Format: #000000) and returns HTML-formatted string
		 * @param color Hex-color of paint (Format: #000000)
		 * @param tx Text to be painted
		 * @return
		 */
		private function colorText(color:String, tx:String):String
		{
			return "<font color=\"" + color + "\">" + tx + "</font>";
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get currentMessage():String 
		{
			return $currentMessage;
		}
		
		public function get lastQueMessage():String 
		{
			return $lastQueMessage;
		}
	}
}