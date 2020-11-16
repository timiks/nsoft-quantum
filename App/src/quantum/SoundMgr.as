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
		public static const sndToggle:String = "sndToggle";
		public static const sndGlobalError:String = "sndGlobalError";
		public static const sndLightFeedback:String = "sndLightFeedback";
		public static const sndClick:String = "sndClick";
		public static const sndFail:String = "sndFail";
		
		// Assets
		[Embed(source = "/../lib/sounds/snd-ok.mp3")]
		private var SuccessSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-error.mp3")]
		private var ErrorSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-message.mp3")]
		private var MessageSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-toggle.mp3")]
		private var ToggleSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-global-error.mp3")]
		private var GlobalErrorSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-light-feedback.mp3")]
		private var LightFeedbackSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-click.mp3")]
		private var ClickSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-fail.mp3")]
		private var FailSound:Class;
		
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
				
				case sndToggle: 
					snd = new ToggleSound() as Sound;
					snd.play();
					break;
				
				case sndGlobalError:
					snd = new GlobalErrorSound() as Sound;
					snd.play();
					break;
					
				case sndLightFeedback:
					snd = new LightFeedbackSound() as Sound;
					snd.play();
					break;
					
				case sndClick:
					snd = new ClickSound() as Sound;
					snd.play();
					break;
					
				case sndFail:
					snd = new FailSound() as Sound;
					snd.play();
					break;
					
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