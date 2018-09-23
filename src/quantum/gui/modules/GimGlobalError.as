package quantum.gui.modules
{
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import quantum.Main;
	import quantum.SoundMgr;
	
	/**
	* ...
	* @author Tim Yusupov
	*/
	public class GimGlobalError extends Sprite
	{
		[Embed(source = "/../lib/graphics/global-error-window-back.png")]
		private var ErrorWindowBackImage:Class;
		
		private const standartMessage:String = "Квантум столкнулся с системной ошибкой. Дальнейшая корректная работа может быть частично или полностью нарушена.";
		
		private var main:Main;
		
		private var win:NativeWindow;
		private var msgTxt:TextField;
		
		private var inited:Boolean = false;
		
		public function GimGlobalError():void {}
		
		public function init():void 
		{
			main = Main.ins;
			
			// Window
			var winOpts:NativeWindowInitOptions = new NativeWindowInitOptions();
			winOpts.type = NativeWindowType.NORMAL;
			winOpts.systemChrome = NativeWindowSystemChrome.STANDARD;
			winOpts.transparent = false;
			winOpts.maximizable = false;
			winOpts.resizable = false;
			
			win = new NativeWindow(winOpts);
			win.stage.align = StageAlign.TOP_LEFT;
			win.stage.scaleMode = StageScaleMode.NO_SCALE;
			win.alwaysInFront = true;
			win.stage.stageWidth = 500;
			win.stage.stageHeight = 200;
			win.title = main.appName + ": cистемная ошибка";
			
			// Background image
			var backImage:Bitmap = new ErrorWindowBackImage();
			addChild(backImage);
			
			// Message textfield
			msgTxt = new TextField();
			msgTxt.defaultTextFormat = new TextFormat("Tahoma", 15, 0xFFFFFF);
			msgTxt.defaultTextFormat.kerning = true;
			msgTxt.autoSize = TextFieldAutoSize.LEFT;
			msgTxt.embedFonts = false;
			msgTxt.multiline = true;
			msgTxt.selectable = false;
			msgTxt.wordWrap = true;
			msgTxt.x = 170;
			msgTxt.y = 50;
			msgTxt.width = 250;
			msgTxt.text = "";
			addChild(msgTxt);
			
			win.stage.addChild(this);
			
			win.addEventListener(Event.CLOSING, function(e:Event):void
			{
				e.preventDefault();
				win.visible = false;
				
				if (main.stQuantumMgr.stage.nativeWindow.visible)
					main.stQuantumMgr.stage.nativeWindow.activate();
			});
			
			// ================================================================================
			
			inited = true;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function showError(errorCode:String):void 
		{
			if (!inited) init();
			
			msgTxt.text = standartMessage + " Код ошибки: " + errorCode;
			
			if (!isVisible)
			{
				win.x = (Capabilities.screenResolutionX / 2) - (win.width / 2);
				win.y = (Capabilities.screenResolutionY / 2) - (win.height / 2);
				win.visible = true;
				main.soundMgr.play(SoundMgr.sndGlobalError);
			}
			
			NativeApplication.nativeApplication.activate(win);
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get isVisible():Boolean
		{
			return win.visible;
		}
	}
}