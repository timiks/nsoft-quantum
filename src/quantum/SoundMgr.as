package quantum {

	import flash.media.Sound;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class SoundMgr {

		public static const sndPrcSuccess:String = "sndPrcSuccess";
		public static const sndPrcError:String = "sndPrcError";
		public static const sndBgPrcToggle:String = "sndBgPrcToggle";
		public static const sndMessage:String = "sndMessage";

		// Assets
		[Embed(source = "/../lib/sounds/snd-ok.mp3")]
		private var SuccessSound:Class;

		[Embed(source = "/../lib/sounds/snd-error.mp3")]
		private var ErrorSound:Class;

		[Embed(source = "/../lib/sounds/snd-toggle-bg-prc.mp3")]
		private var ToggleBgPrcSound:Class;
		
		[Embed(source = "/../lib/sounds/snd-message.mp3")]
		private var MessageSound:Class;

		private var snd:Sound;

		public function SoundMgr():void {


		}

		public function play(soundID:String):void {

			switch (soundID) {
				case sndPrcSuccess:
					snd = new SuccessSound() as Sound;
					snd.play();
					break;

				case sndPrcError:
					snd = new ErrorSound() as Sound;
					snd.play();
					break;

				case sndBgPrcToggle:
					snd = new ToggleBgPrcSound() as Sound;
					snd.play();
					break;
					
				case sndMessage:
					snd = new MessageSound() as Sound;
					snd.play();
					break;
			}

		}

	}

}