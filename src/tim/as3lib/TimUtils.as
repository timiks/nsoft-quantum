package tim.as3lib 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public final class TimUtils 
	{
		public function TimUtils():void {}
		
		public static function shuffleArray(arrayReference:Array):void 
		{
			var randomIndex:int;
			var itemAtIndex:Object;
			
			for (var i:int = arrayReference.length-1; i >=0; i--)
			{
				randomIndex = Math.floor(Math.random() * (i+1));
				itemAtIndex = arrayReference[randomIndex];
				arrayReference[randomIndex] = arrayReference[i];
				arrayReference[i] = itemAtIndex;
			}
			
			arrayReference = null;
			itemAtIndex = null;
		}
		
		public static function trimSpaces(str:String):String
		{
			return str.replace(/^\s*(.*?)\s*$/, "$1");
		}
	}
}