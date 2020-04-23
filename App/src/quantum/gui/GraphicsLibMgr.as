package quantum.gui 
{
	import flash.display.GraphicsSolidFill;
	import flash.display.IGraphicsData;
	import flash.display.Shape;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class GraphicsLibMgr 
	{
		public static const plainShape_plusSign:String = "Plus_sign";
		
		private var plainShapesLib:PlainShapesLib1;
		
		public function GraphicsLibMgr():void 
		{
			init();
		}
		
		private function init():void 
		{
			plainShapesLib = new PlainShapesLib1();
		}
		
		public function getPlainShape(id:String, fillColor:uint):Shape 
		{
			var sh:Shape = new Shape();
			var gd:Vector.<IGraphicsData>;
			
			plainShapesLib.gotoAndStop(id);
			gd = plainShapesLib.graphics.readGraphicsData();
			(gd[0] as GraphicsSolidFill).color = fillColor;
			sh.graphics.drawGraphicsData(gd);
			
			return sh;
		}
	}
}