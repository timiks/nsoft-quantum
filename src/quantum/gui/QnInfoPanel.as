package quantum.gui 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
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
			if (color == null) color = "#0075BF";
			
			(disOb.ipo.tf as TextField).htmlText = colorText(color, text);

			if ((disOb as MovieClip).isPlaying)
			{
				disOb.gotoAndPlay(10);
			} 
			
			else
			{
				disOb.gotoAndPlay(1);
			}
			
			switch (color) 
			{
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
	}
}