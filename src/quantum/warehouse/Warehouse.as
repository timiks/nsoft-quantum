package quantum.warehouse
{
	
	/**
	 * [!] This class should be active manager and be called WarehouseMgr
	 * @author Tim Yusupov
	 */
	public class Warehouse
	{
		// Warehouse IDs are used directly in code and [!] may be saved in user data
		public static const BEIJING:String = "Beijing";
		public static const CANTON:String = "Canton";
		public static const SHENZHEN_SEO_TMP:String = "Shenzhen-SEO";
		public static const SHENZHEN_CFF_TMP:String = "Shenzhen-CFF";
		
		private static var $entities:Vector.<WarehouseEntity>;
		
		public static function get entitiesList():Vector.<WarehouseEntity>
		{
			if ($entities == null)
			{
				// [!] Must add WH entities here and app will be aware of them
				$entities = new Vector.<WarehouseEntity>();
				$entities.push(new WarehouseEntity(BEIJING, "Пекин"));
				$entities.push(new WarehouseEntity(CANTON, "Кантон"));
				$entities.push(new WarehouseEntity(SHENZHEN_SEO_TMP, "SEO (Шэньчжэнь) КАК КАНТОН"));
				$entities.push(new WarehouseEntity(SHENZHEN_CFF_TMP, "CFF (Шэньчжэнь) КАК КАНТОН"));
			}
			
			return $entities;
		}
		
		public static function getByID(ID:String):WarehouseEntity
		{
			for each (var whe:WarehouseEntity in $entities) 
			{
				if (whe.ID == ID) return whe;
			}
			
			throw new Error("No warehouse entity with ID: " + ID);
			return null;
		}
		
		public function Warehouse():void {}
	}
}