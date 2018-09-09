package quantum.product 
{
		
	/**
	 * Data entity for Product
	 * 09.09.18
	 * @author Tim Yusupov
	 */
	public class Product 
	{
		private var $id:int;
		private var $title:String;
		private var $sku:String;
		private var $price:Number;
		private var $weight:Number;
		private var $imgFile:String;
		private var $note:String;
		
		public function Product():void 
		{
			
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
	}
}