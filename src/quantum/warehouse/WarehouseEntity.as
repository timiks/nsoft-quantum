package quantum.warehouse 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class WarehouseEntity 
	{
		private var $ID:String;
		private var $russianTitle:String;
		private var $uniqueColor:uint;
		private var $uiDisabled:Boolean;
			
		public function WarehouseEntity(
			ID:String, russianTitle:String, uiDisabled:Boolean = false, 
			uniqueColor:uint = 0 /* 0 — means "no color" */):void 
		{
			$ID = ID;
			$russianTitle = russianTitle;
			$uniqueColor = uniqueColor;
			$uiDisabled = uiDisabled;
		}
		
		public function get ID():String 
		{
			return $ID;
		}
		
		public function get russianTitle():String 
		{
			return $russianTitle;
		}
		
		public function get uniqueColor():uint 
		{
			return $uniqueColor;
		}
		
		public function get uiDisabled():Boolean 
		{
			return $uiDisabled;
		}
	}
}