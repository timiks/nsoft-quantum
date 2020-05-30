package quantum.gui.elements
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import quantum.gui.modules.GroupsGim;
	import quantum.gui.modules.QnManagerGim;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BigTextInput
	{
		private var baseState:QnManagerGim;
		private var grpCnt:GroupsGim;
		private var tfstripe:MovieClip;
		private var preservedText:String;
		
		private var $tf:TextField;
		private var $focused:Boolean;
		
		private const EMPTY_TITLE_PLACEHOLDER:String = "[Безымянная группа]";
		
		public function BigTextInput():void {}
		
		public function init(baseState:QnManagerGim, grpCnt:GroupsGim, tfstripe:MovieClip):void
		{
			this.baseState = baseState;
			this.grpCnt = grpCnt;
			this.tfstripe = tfstripe;
			
			tf.text = "";
			tf.visible = false;
			tfstripe.visible = false;
			tfstripe.mouseEnabled = false;
			
			// Listeners
			tf.addEventListener(FocusEvent.FOCUS_IN, focusIn);
			tf.addEventListener(FocusEvent.FOCUS_OUT, focusOut);
			tf.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			tf.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			tf.addEventListener(MouseEvent.CLICK, mouseClick);
			tf.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			tf.addEventListener("change", textChange);
			baseState.stage.nativeWindow.addEventListener(Event.DEACTIVATE, windowFocusOut);
		}
		
		private function windowFocusOut(e:Event):void
		{
			focusOut(null);
		}
		
		private function mouseClick(e:MouseEvent):void
		{
			tf.setSelection(0, tf.text.length);
		}
		
		private function focusIn(e:FocusEvent):void
		{
			if (tf.text == EMPTY_TITLE_PLACEHOLDER) tf.text = "";
			
			preservedText = tf.text;
			
			$focused = true;
			tfstripe.visible = true;
			grpCnt.stopSelTimer();
		}
		
		private function focusOut(e:FocusEvent):void
		{
			$focused = false;
			tfstripe.visible = false;
			baseState.stage.focus = grpCnt;
			grpCnt.grpTitleInputFocusOut();
		}
		
		private function textChange(e:Event):void
		{
			if (focused)
			{
				grpCnt.updateUiElementData("selGrpTitle", tf.text);
			}
		}
		
		private function keyDown(e:KeyboardEvent):void
		{
			switch (e.keyCode)
			{
				case Keyboard.ENTER: 
					baseState.stage.focus = null;
					break;
				
				case Keyboard.ESCAPE: 
					cancelEditing();
					e.stopPropagation();
					break;
				
				case Keyboard.DELETE: 
					e.stopPropagation();
					break;
			}
		}
		
		private function mouseOut(e:MouseEvent):void
		{
		
		}
		
		private function mouseOver(e:MouseEvent):void
		{
		
		}
		
		private function cancelEditing():void
		{
			grpCnt.updateUiElementData("selGrpTitle", preservedText); // Roll back changes
			baseState.stage.focus = null;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function show(text:String):void
		{
			text = text == "" ? EMPTY_TITLE_PLACEHOLDER : text;
			tf.text = text;
			tf.visible = true;
		}
		
		public function hide():void
		{
			tf.text = "";
			tf.visible = false;
			$focused = false;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		public function get tf():TextField
		{
			return $tf;
		}
		
		public function set tf(value:TextField):void
		{
			$tf = value;
		}
		
		public function get focused():Boolean
		{
			return $focused;
		}
	}
}