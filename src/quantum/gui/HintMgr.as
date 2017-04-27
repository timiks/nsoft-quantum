package quantum.gui {

	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class HintMgr {

		private const HINT_STANDART:int = 1;
		private const HINT_WITH_HANDLER:int = 2;

		private var hints:Dictionary;
		private var hintDisOb:HintDisOb;
		private var hintsContainer:Sprite;

		public function HintMgr():void {}

		public function init(container:Sprite):void {

			hintsContainer = container;
			hints = new Dictionary();

		}

		public function registerHint(disOb:InteractiveObject, hint:Hint):void {

		}

		public function registerHintWithHandler(disOb:InteractiveObject, textHandler:Function):void {

			switchListeners(disOb);

			if (hints[disOb] == null)
				hints[disOb] = new Hint(disOb, HINT_WITH_HANDLER, null, textHandler);

		}

		public function unregisterHint(disOb:InteractiveObject):void {

			switchListeners(disOb, false);
			// [To-Do Here ↓]: Set hint object in dictionary to null where disOb is a key

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
			var hintText:String = "";
			switch (hint.type) {

				case HINT_WITH_HANDLER:
					hintText = hint.textHandler();
					break;

				default:
					hintText = null;
					break;

			}

			if (hintText == null) return;

			hintDisOb = new HintDisOb();
			hintDisOb.mouseEnabled = false;
			hintDisOb.x = e.target.x;
			hintDisOb.y = e.target.y;
			hintDisOb.txt.autoSize = TextFieldAutoSize.LEFT;
			hintDisOb.txt.text = hintText; // Assign text to hint
			hintDisOb.scaleFrame.width = hintDisOb.txt.width + 5;
			trace("hintDisOb.scaleFrame.width:", hintDisOb.scaleFrame.width);
			trace("hintDisOb.txt.width:", hintDisOb.txt.width);

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