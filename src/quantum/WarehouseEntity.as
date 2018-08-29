package quantum 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class WarehouseEntity 
	{
		private var $ID:String;
		private var $russianTitle:String;
			
		public function WarehouseEntity(ID:String, russianTitle:String):void 
		{
			$ID = ID;
			$russianTitle = russianTitle;
		}
		
		public function get ID():String 
		{
			return $ID;
		}
		
		public function get russianTitle():String 
		{
			return $russianTitle;
		}
	}
}