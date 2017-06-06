package quantum.gui {

	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class HintMgr {

		private const HINT_STANDART:int = 1;
		private const HINT_WITH_HANDLER:int = 2;

		private var hintsContainer:Sprite;
		private var hints:Dictionary;
		private var hintDisOb:Sprite;
		private var txt:TextField;
		private var scaleFrame:Shape;
		private var rect:Rectangle;

		public function HintMgr():void {}

		public function init(container:Sprite):void {

			hintsContainer = container;
			hints = new Dictionary();

			// Display object of a hint
			hintDisOb = new Sprite();
			hintDisOb.mouseEnabled = false;

			// Hint text field
			txt = new TextField();
			txt.defaultTextFormat = new TextFormat("Tahoma", 15, 0x585F63);
			txt.embedFonts = false;
			txt.autoSize = TextFieldAutoSize.LEFT;
			txt.multiline = true;
			txt.x = 2;

			// Scale frame
			scaleFrame = new Shape();
			rect = new Rectangle();

			hintDisOb.addChild(scaleFrame);
			hintDisOb.addChild(txt);

		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function registerHint(disOb:InteractiveObject, hintText:String):void {
			
			switchListeners(disOb);

			if (hints[disOb] == null)
				hints[disOb] = new Hint(disOb, HINT_STANDART, hintText);
				
		}

		public function registerHintWithHandler(disOb:InteractiveObject, textHandler:Function):void {

			switchListeners(disOb);

			if (hints[disOb] == null)
				hints[disOb] = new Hint(disOb, HINT_WITH_HANDLER, null, textHandler);

		}

		public function unregisterHint(disOb:InteractiveObject):void {

			switchListeners(disOb, false);
			hints[disOb] = null;
			delete hints[disOb];

		}

		// ================================================================================

		private function switchListeners(disOb:InteractiveObject, act:Boolean = true):void {

			if (!act) {
				disOb.removeEventListener(MouseEvent.ROLL_OVER, showHint);
				disOb.removeEventListener(MouseEvent.ROLL_OUT, hideHint);
				return;
			}

			disOb.addEventListener(MouseEvent.ROLL_OVER, showHint);
			disOb.addEventListener(MouseEvent.ROLL_OUT, hideHint);

		}

		private function showHint(e:MouseEvent):void {

			// Retrieve hint from display object reference
			var hint:Hint = hints[e.currentTarget] as Hint;

			if (hint == null) return;

			// Prepare text
			var hintText:String;
			switch (hint.type) {
				
				case HINT_STANDART:
					hintText = hint.text;
					break;
				
				case HINT_WITH_HANDLER:
					hintText = hint.textHandler();
					break;

				default:
					hintText = null;
					break;

			}

			if (hintText == null) return;

			hintDisOb.x = e.target.x;
			hintDisOb.y = e.target.y;
			txt.text = hintText; // Assign text to hint

			rect.width = txt.textWidth + 7;
			rect.height = txt.textHeight + 4;

			scaleFrame.graphics.clear();
			scaleFrame.graphics.beginFill(0xF9F9F9);
			scaleFrame.graphics.drawRect(0, 0, rect.width, rect.height);
			scaleFrame.graphics.endFill();

			scaleFrame.graphics.lineStyle(1, 0xB7BABC);
			scaleFrame.graphics.drawRect(0, 0, rect.width, rect.height);

			alignHint(null);
			hintsContainer.addChild(hintDisOb);
			hintsContainer.stage.addEventListener(MouseEvent.MOUSE_MOVE, alignHint);

		}

		private function hideHint(e:MouseEvent):void {

			if (hintsContainer.numChildren == 0) return;

			hintsContainer.removeChildAt(0);
			hintsContainer.stage.removeEventListener(MouseEvent.MOUSE_MOVE, alignHint);

		}

		private function alignHint(e:MouseEvent):void {

			if((hintsContainer.stage.mouseX + hintDisOb.width + 50) > hintsContainer.stage.stageWidth) {

				hintDisOb.x = hintsContainer.stage.mouseX - 3 - hintDisOb.width;
				hintDisOb.y = hintsContainer.stage.mouseY + 15;

			} else {

				hintDisOb.x = hintsContainer.stage.mouseX + 15;
				hintDisOb.y = hintsContainer.stage.mouseY + 15;

			}

		}

	}

}