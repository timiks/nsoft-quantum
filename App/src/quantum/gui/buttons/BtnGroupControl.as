package quantum.gui.buttons 
{
	import flash.display.CapsStyle;
	import flash.display.GraphicsSolidFill;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import quantum.Main;
	import quantum.gui.Colors;
	import quantum.gui.GraphicsLibMgr;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BtnGroupControl extends SimpleButton
	{
		private static const upStateFillColor:uint 			= 0xF9F9F9;
		private static const upStateForegroundColor:uint 	= 0x646464;
		private static const overStateFillColor:uint 		= 0x525252;
		private static const overStateForegroundColor:uint 	= Colors.UI_GROUP_SELECTION;
		
		private var main:Main;
		private var glm:GraphicsLibMgr;
		
		private var upStateGraphics:Sprite;
		private var overStateGraphics:Sprite;
		
		public function BtnGroupControl():void 
		{
			main = Main.ins;
			glm = main.graphicsLibMgr;
			
			initGraphics();
			super(upStateGraphics, overStateGraphics, overStateGraphics, upStateGraphics);
		}
		
		private function initGraphics():void 
		{
			upStateGraphics = drawMainFigure(upStateForegroundColor, upStateFillColor, 2);
			overStateGraphics = drawMainFigure(overStateForegroundColor, overStateFillColor, 0, true);
		}
		
		private function drawMainFigure(foregroundColor:uint, backgroundColor:uint, outlineSize:int, noStroke:Boolean = false):Sprite 
		{
			var s:Sprite = new Sprite();
			
			var positionOffset:int = outlineSize / 2;
			var posXY:int = noStroke ? 0 : positionOffset;
			const w:int = 40;
			const h:int = 32;
			
			// Back rectangle with round corners
			// · Fill
			s.graphics.beginFill(backgroundColor, 1);
			s.graphics.drawRoundRect(posXY, posXY, w-outlineSize, h-outlineSize, 6);
			s.graphics.endFill();
			
			// · Outline
			if (!noStroke) 
			{
				s.graphics.lineStyle(outlineSize, foregroundColor, 1, true, "normal", CapsStyle.ROUND, JointStyle.ROUND);
				s.graphics.drawRoundRect(posXY, posXY, w-outlineSize, h-outlineSize, 8);
			}
			
			// Plus sign
			var plusShape:Shape = glm.getPlainShape(GraphicsLibMgr.plainShape_plusSign, foregroundColor);
			
			s.addChild(plusShape);
			plusShape.x = (plusShape.parent.width-plusShape.width) / 2;
			plusShape.y = (plusShape.parent.height-plusShape.height) / 2;
			
			return s;
		}
	}
}