package quantum.gui
{
	import flash.display.InteractiveObject;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class Hint
	{
		private var $disOb:InteractiveObject;
		private var $type:int;
		private var $text:String;
		private var $textHandler:Function;
		
		public function Hint(disOb:InteractiveObject, type:int, text:String = null, textHandler:Function = null):void
		{
			this.disOb = disOb;
			this.type = type;
			this.text = text;
			this.textHandler = textHandler;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get disOb():InteractiveObject
		{
			return $disOb;
		}
		
		public function set disOb(value:InteractiveObject):void
		{
			$disOb = value;
		}
		
		public function get type():int
		{
			return $type;
		}
		
		public function set type(value:int):void
		{
			$type = value;
		}
		
		public function get text():String
		{
			return $text;
		}
		
		public function set text(value:String):void
		{
			$text = value;
		}
		
		public function get textHandler():Function
		{
			return $textHandler;
		}
		
		public function set textHandler(value:Function):void
		{
			$textHandler = value;
		}
	}
}