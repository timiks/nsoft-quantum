package quantum.gui 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import quantum.Main;
	import quantum.SoundMgr;
	import quantum.states.StQuantumManager;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class QnInfoPanel 
	{
		private var main:Main;
		private var qnState:StQuantumManager;
		
		private var $currentMessage:String;
		
		private var cmp:QnManagerComposition;
		private var placementCoordY:Number;
		private var disOb:QuantumInfoPanel;
		
		public function QnInfoPanel(qnState:StQuantumManager, cmp:QnManagerComposition):void 
		{
			this.qnState = qnState;
			this.cmp = cmp;
		}
		
		public function init():void 
		{
			main = Main.ins;
			disOb = cmp.infopanel;
			disOb.mouseEnabled = false;
			disOb.mouseChildren = false;
		}
		
		public function showMessage(text:String, color:String = null):void
		{
			if (color == null) color = Colors.MESSAGE;
			
			var noSound:Boolean = false;
			
			if (disOb.isPlaying && $currentMessage == text)
				noSound = true;
			
			(disOb.ipo.tf as TextField).htmlText = colorText(color, text);
			$currentMessage = text;
			
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
					main.soundMgr.play(SoundMgr.sndMessage);
					break;
					
				case Colors.BAD:
					main.soundMgr.play(SoundMgr.sndPrcError);
					break;
					
				default:
					
					break;
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
	}
}