package quantum.product 
{
	import flash.display.BitmapData;
		
	/**
	 * Data entity for Product
	 * Used as entry (record) in ProductsMgr
	 * 09.09.18
	 * @author Tim Yusupov
	 */
	public class Product 
	{
		// Data properties
		private var $id:int;
		public static const prop_id:String = "id";
		
		private var $sku:String; /* GUI */
		public static const prop_sku:String = "sku";
		
		private var $price:Number; /* GUI */
		public static const prop_price:String = "price";
		
		private var $weight:Number; /* GUI */
		public static const prop_weight:String = "weight";
		
		private var $imgFile:String;
		public static const prop_imgFile:String = "imgFile";
		
		private var $note:String; /* GUI */
		public static const prop_note:String = "note";
		
		// App properties
		private var $image:BitmapData;
		public static const prop_image:String = "image";
		
		private var $weightStatList:Vector.<Number>; // Weight values from gathered statistics by TrackScript
		private var $dataXml:XML; // associated XML-entry in data
		
		/**
		 * Constructor for basic data entity.
		 * Used ONLY inside ProductsMgr (mostly) and DataMgr (to prepare loaded data entites for use in app)
		 */
		public function Product():void 
		{
			/* No properties initialization inside the constructor. */
			/* ProductsMgr directly sets properties for new product. */
			/* DataMgr is allowed to do it only when it's transforming XML-objects to  */
			/* their corresponding app entities when loading occurs (as an exception). */
		}
		
		public function get id():int 
		{
			return $id;
		}
		
		public function set id(value:int):void 
		{
			$id = value;
		}
		
		public function get sku():String 
		{
			return $sku;
		}
		
		public function set sku(value:String):void 
		{
			$sku = value;
		}
		
		public function get price():Number 
		{
			return $price;
		}
		
		public function set price(value:Number):void 
		{
			if (isNaN(value)) value = 0;
			
			$price = value;
		}
		
		public function get weight():Number 
		{
			return $weight;
		}
		
		public function set weight(value:Number):void 
		{
			if (isNaN(value)) value = 0;
			
			$weight = value;
		}
		
		public function get imgFile():String 
		{
			return $imgFile;
		}
		
		public function set imgFile(value:String):void 
		{
			$imgFile = value;
		}
		
		public function get note():String 
		{
			return $note;
		}
		
		public function set note(value:String):void 
		{
			$note = value;
		}
		
		public function get image():BitmapData 
		{
			return $image;
		}
		
		public function set image(value:BitmapData):void 
		{
			$image = value;
		}
		
		public function get dataXml():XML 
		{
			return $dataXml;
		}
		
		public function set dataXml(value:XML):void 
		{
			$dataXml = value;
		}
		
		public function get weightStatList():Vector.<Number> 
		{
			if ($weightStatList == null)
				$weightStatList = new Vector.<Number>();
				
			return $weightStatList;
		}
	}
}