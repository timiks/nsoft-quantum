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
			
		public function WarehouseEntity(ID:String, russianTitle:String, uniqueColor:uint = 0):void 
		{
			$ID = ID;
			$russianTitle = russianTitle;
			$uniqueColor = uniqueColor;
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
	}
}