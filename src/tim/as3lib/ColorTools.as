package tim.as3lib 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ColorTools 
	{
		public function ColorTools():void {}
		
		public static function shadeColor(color:uint, percent:Number):uint
		{   
			var f:uint = color;
			var t:int = percent < 0 ? 0 : 255;
			var p:Number = percent < 0 ? percent * -1 : percent;
			
			var R:uint = f >> 16;
			var G:uint = f >> 8 & 0x00FF;
			var B:uint = f & 0x0000FF;
			
			return parseInt((0x1000000 + (Math.round((t-R)*p)+R) * 0x10000 +
				(Math.round((t-G)*p)+G)*0x100+(Math.round((t-B)*p)+B)).toString(16).slice(1), 16);
		}
	}
}