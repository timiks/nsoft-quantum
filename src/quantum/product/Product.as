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
		
		private var $title:String;
		public static const prop_title:String = "title";
		
		private var $sku:String;
		public static const prop_sku:String = "sku";
		
		private var $englishName:String;
		public static const prop_englishName:String = "englishName";
		
		private var $price:Number;
		public static const prop_price:String = "price";
		
		private var $weight:Number;
		public static const prop_weight:String = "weight";
		
		private var $imgFile:String;
		public static const prop_imgFile:String = "imgFile";
		
		private var $note:String;
		public static const prop_note:String = "note";
		
		private var $classID:int;
		public static const prop_classID:String = "classID";
		
		// App properties
		private var $image:BitmapData;
		public static const prop_image:String = "image";
		
		private var $dataXml:XML; // associated XML-entry in data
		
		/**
		 * Constructor for basic data entity. Used ONLY inside of ProductsMgr.
		 */
		public function Product():void 
		{
			/* No properties initialization inside the constructor */
			/* ProductsMgr directly sets properties for new product */
		}
		
		public function get id():int 
		{
			return $id;
		}
		
		public function set id(value:int):void 
		{
			$id = value;
		}
		
		public function get title():String 
		{
			return $title;
		}
		
		public function set title(value:String):void 
		{
			$title = value;
		}
		
		public function get sku():String 
		{
			return $sku;
		}
		
		public function set sku(value:String):void 
		{
			$sku = value;
		}
		
		public function get englishName():String 
		{
			return $englishName;
		}
		
		public function set englishName(value:String):void 
		{
			$englishName = value;
		}
		
		public function get price():Number 
		{
			return $price;
		}
		
		public function set price(value:Number):void 
		{
			$price = value;
		}
		
		public function get weight():Number 
		{
			return $weight;
		}
		
		public function set weight(value:Number):void 
		{
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
		
		public function get classID():int 
		{
			return $classID;
		}
		
		public function set classID(value:int):void 
		{
			$classID = value;
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
	}
}