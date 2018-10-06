package quantum.warehouse
{
	
	/**
	 * [!] This class should be active manager and be called WarehouseMgr
	 * @author Tim Yusupov
	 */
	public class Warehouse
	{
		// Warehouse IDs are used directly in code and [!] may be saved in user data
		public static const NONE:String = "[None]"; // Special ID, means "No warehouse assigned"
		public static const BEIJING:String = "Beijing";
		public static const CANTON:String = "Canton";
		public static const SHENZHEN_SEO:String = "Shenzhen-SEO";
		public static const SHENZHEN_CFF:String = "Shenzhen-CFF";
		
		private static var $entities:Vector.<WarehouseEntity>;
		
		public static function get entitiesList():Vector.<WarehouseEntity>
		{
			if ($entities == null)
			{
				// Add WH entities here and app will be aware of them
				$entities = new Vector.<WarehouseEntity>();
				$entities.push(new WarehouseEntity(NONE, "[Без склада]"));
				$entities.push(new WarehouseEntity(BEIJING, "Пекин"));
				$entities.push(new WarehouseEntity(CANTON, "Кантон"));
				$entities.push(new WarehouseEntity(SHENZHEN_SEO, "SEO (Шэньчжэнь)"));
				$entities.push(new WarehouseEntity(SHENZHEN_CFF, "CFF (Шэньчжэнь)"));
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