package quantum
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class SoundMgr
	{
		public static const sndSuccess:String = "sndSuccess";
		public static const sndError:String = "sndError";
		public static const sndMessage:String = "sndMessage";
		public static const sndBgPrcToggle:String = "sndBgPrcToggle";
		public static const sndGlobalError:String = "sndGlobalError";
		
		// Assets
		[Embed(source = "/../lib/sounds/snd-ok.mp3")]
		private var SuccessSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-error.mp3")]
		private var ErrorSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-message.mp3")]
		private var MessageSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-toggle-bg-prc.mp3")]
		private var ToggleBgPrcSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-global-error.mp3")]
		private var GlobalErrorSound:Class;
		
		private var snd:Sound;
		private var playing:Boolean;
		private var tmr:Timer;
		
		public function SoundMgr():void 
		{
			tmr = new Timer(600, 1);
		}
		
		public function play(soundID:String, priority:Boolean = false):void
		{
			if (!priority && playing) return;
			
			switch (soundID)
			{
				case sndSuccess: 
					snd = new SuccessSound() as Sound;
					snd.play();
					break;
				
				case sndError: 
					snd = new ErrorSound() as Sound;
					snd.play();
					break;
				
				case sndMessage: 
					snd = new MessageSound() as Sound;
					snd.play();
					break;
				
				case sndBgPrcToggle: 
					snd = new ToggleBgPrcSound() as Sound;
					snd.play();
					break;
				
				case sndGlobalError:
					snd = new GlobalErrorSound() as Sound;
					snd.play();
					
				default: 
					return;
					break;
			}
			
			playing = true;
			tmr.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void 
			{
				playing = false;
				e.currentTarget.removeEventListener(e.type, arguments.callee);
			});
			tmr.start();
		}
	}
}