package quantum.product 
{
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import quantum.Main;
	import quantum.data.DataMgr;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	import quantum.product.images.ImageCacheMgr;
	import quantum.product.images.ImageLoader;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProductsMgr 
	{
		private var $events:EventDispatcher;
		
		private var main:Main;
		private var dm:DataMgr; // Shortcut for DataMgr
		
		private var imgCacheMgr:ImageCacheMgr;
		private var imgLoader1:ImageLoader;
		private var imgLoader2:ImageLoader;
		private var imgLoader3:ImageLoader;
		private var imgLoader4:ImageLoader;
		private var imgLoader5:ImageLoader;
		private var imgLoader6:ImageLoader;
		private var imgLoader7:ImageLoader;
		private var imgLoader8:ImageLoader;
		
		private var idCounter:int;
		private var productsList:Vector.<Product>;
		
		public function ProductsMgr():void 
		{
			main = Main.ins;
			dm = main.dataMgr;
			$events = new EventDispatcher();
		}
		
		public function init():void 
		{
			productsList = dm.getAllProducts();
			idCounter = dm.opProductsIdCounter(DataMgr.OP_READ);
			
			if (idCounter == 0) idCounter = 1;
			
			if (Capabilities.isDebugger && !DevSettings.loadProductsImages) return;
			
			// Cache manager
			imgCacheMgr = new ImageCacheMgr(this);
			
			// Initial load and process of all product images
			imgLoader1 = new ImageLoader(this, imgCacheMgr);
			imgLoader2 = new ImageLoader(this, imgCacheMgr);
			imgLoader3 = new ImageLoader(this, imgCacheMgr);
			imgLoader4 = new ImageLoader(this, imgCacheMgr);
			imgLoader5 = new ImageLoader(this, imgCacheMgr);
			imgLoader6 = new ImageLoader(this, imgCacheMgr);
			imgLoader7 = new ImageLoader(this, imgCacheMgr);
			imgLoader8 = new ImageLoader(this, imgCacheMgr);
			
			if (productsList.length > 0) 
			{
				var bunchOfImages:Vector.<String> = new Vector.<String>();
				for each (var p:Product in productsList) 
				{
					bunchOfImages.push(p.imgFile);
				}
				
				registerBunchOfImageFilesForLoading(bunchOfImages);
				p = null;
			}
		}
		
		public function dismiss():void 
		{
			productsList = null;
		}
		
		private function registerBunchOfImageFilesForLoading(list:Vector.<String>):void 
		{
			var count:int = list.length;
			var remainder:int = count % 8; // 8 — amount of loaders
			var amountPerLoader:int = (count - remainder) / 8;
			
			var i:int;
			var il:ImageLoader;
			for (i = 0; i < count; i++) 
			{	
				if (i <= amountPerLoader-1)
					il = imgLoader1;
					
				if (i > amountPerLoader-1) 
					il = imgLoader2;
				
				if (i > (amountPerLoader-1)*2)
					il = imgLoader3;
					
				if (i > (amountPerLoader-1)*3)
					il = imgLoader4;
					
				if (i > (amountPerLoader-1)*4)
					il = imgLoader5;
					
				if (i > (amountPerLoader-1)*5)
					il = imgLoader6;
					
				if (i > (amountPerLoader-1)*6)
					il = imgLoader7;
					
				if (i > (amountPerLoader-1)*7)
					il = imgLoader8;
					
				il.registerImageFileForLoading(list[i] as String);
			}
		}
		
		private function registerSingleImageFileForLoading(imgFilePath:String):void 
		{
			imgLoader1.registerImageFileForLoading(imgFilePath);
		}
		
		// ================================================================================
		
		/**
		 * Adds new product entry to the base and returns created entry.
		 * Parameters of the method are product's data entity properties 
		 * which is used to initialize new product's entry. No extra properties 
		 * as parameters should be here in method's signature — only used ones to
		 * initialize new product's entry. The method used ONLY inside ProductsMgr.
		 */
		private function addNewProduct(imgFilePath:String = null):Product 
		{
			var newProductEntry:Product = new Product();
			
			// Set product's properties to initial values
			newProductEntry.id = getNewUniqueID(); // New product's ID always set here
			newProductEntry.sku = "";
			newProductEntry.price = 0;
			newProductEntry.weight = 0;
			newProductEntry.imgFile = imgFilePath;
			newProductEntry.note = "";
			
			productsList.push(newProductEntry);
			
			dm.opProduct(newProductEntry.id, DataMgr.OP_ADD, null, newProductEntry as Product);
			registerSingleImageFileForLoading(imgFilePath);
			
			return newProductEntry;
		}
		
		public function getProductByID(id:int):Product
		{
			for each (var p:Product in productsList) 
			{
				if (p.id == id)
				{
					return p;
				}
			}
			
			trace("No product with ID " + id);
			return null;
		}
		
		private function getNewUniqueID():int
		{
			/* Current value of the counter is set as ID to new product */
			var setId:int = idCounter; 
			/* Then counter increment occurs and new value updated in the database (in one step) */
			dm.opProductsIdCounter(DataMgr.OP_UPDATE, ++idCounter);
			/* Returned value is the value BEFORE increment */
			return setId;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		/**
		 * Main interface method-function to query info about products, create, remove and update them
		 * INCLUDED INTERNAL OPERATIONS 
		 */
		public function opProduct(id:int, op:String, field:String = null, value:* = null, appField:Boolean = false):* 
		/* Only READ, UPDATE and REMOVE operations. Creation allowed only inside */
		{
			var p:Product = getProductByID(id);
			
			if (op == DataMgr.OP_READ) 
			{
				var retVal:*;
				
				retVal = p[field];
				
				/* Notes special */
				retVal = (field == Product.prop_note && retVal == null) ? "" : retVal;
				
				return retVal;
			}
			
			else
			
			if (op == DataMgr.OP_UPDATE)
			{
				p[field] = value;
				events.dispatchEvent(new DataEvent(DataEvent.DATA_UPDATE, id, field));
				if (!appField) dm.opProduct(id, DataMgr.OP_UPDATE, field, value);
			}
			
			else
			
			if (op == DataMgr.OP_REMOVE) 
			{
				// No implementation for this operation in early versions
			}
		} 
		
		/**
		 * Checks product entry existence in base by imgPath. If it doesn't exist, new product is created with this imgPath. 
		 * Found product's ID is returned.
		 */
		public function checkProductByImgPath(imgPath:String):int 
		{
			var p:Product;
			for each (p in productsList) 
			{
				if (p.imgFile == imgPath)
				{
					return p.id; // Return existing product's entry
				}
			}
			
			// No product with this imgPath found > add new entry
			p = addNewProduct(imgPath);
			return p.id;
		}
		
		public function checkProductBySKU(skuValue:String):int
		{
			if (skuValue == "")
				return -1;
			
			var p:Product;
			for each (p in productsList) 
			{
				if (p.sku == skuValue) 
				{
					return p.id;
				}
			}
			
			return -1;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
		
		public function get imagesLoadingActive():Boolean
		{
			return imgLoader1.loadingActive || imgLoader2.loadingActive || imgLoader3.loadingActive || imgLoader4.loadingActive;
		}
	}
}