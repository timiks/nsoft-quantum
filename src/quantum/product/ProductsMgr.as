package quantum.product 
{
	import flash.events.EventDispatcher;
	import quantum.Main;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProductsMgr 
	{
		private var main:Main;
		private var productsList:Vector.<Product>;
		private var $events:EventDispatcher;
		
		public function ProductsMgr():void 
		{
			main = Main.ins;
			$events = new EventDispatcher();
			productsList = main.dataMgr.getAllProducts();
		}
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
	}
}