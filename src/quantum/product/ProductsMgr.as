package quantum.product 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import quantum.Main;
	import quantum.data.DataMgr;
	import quantum.events.DataEvent;
	import quantum.gui.SquareItem;
	import sk.yoz.image.ImageResizer;
	import sk.yoz.math.ResizeMath;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProductsMgr 
	{
		private const IMG_SQUARE_SIZE:int = SquareItem.SQUARE_SIZE;
		
		private var $events:EventDispatcher;
		
		private var main:Main;
		private var dm:DataMgr; // Shortcut for DataMgr
		
		private var idCounter:int;
		private var productsList:Vector.<Product>;
		
		private var fst:FileStream;
		private var ldr:Loader;
		private var imgFile:File;
		private var ba:ByteArray;
		private var imgLoadingQueue:Vector.<String>;
		private var queActive:Boolean;
		
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
			
			// Setup stuff for product images processing
			fst = new FileStream();
			ldr = new Loader();
			imgFile = new File();
			ba = new ByteArray();
			imgLoadingQueue = new Vector.<String>();
			
			// · All time listeners
			fst.addEventListener(Event.COMPLETE, imgLoading_s2_readFile);
			fst.addEventListener(IOErrorEvent.IO_ERROR, imgLoadingIoError);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoading_s3_processImg);
			
			// Initial load and process of all product images
			for each (var p:Product in productsList) 
			{
				addToImgLoadingQueue(p.imgFile);
			}
		}
		
		public function dismiss():void 
		{
			fst.removeEventListener(Event.COMPLETE, imgLoading_s2_readFile);
			fst.removeEventListener(IOErrorEvent.IO_ERROR, imgLoadingIoError);
			ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, imgLoading_s3_processImg);
			
			fst = null;
			ldr = null;
			imgFile = null;
			ba = null;
			imgLoadingQueue = null;
		}
		
		/**
		 * Product image processing
		 * ================================================================================
		 */
		
		private function addToImgLoadingQueue(imgFilePath:String):void 
		{
			imgLoadingQueue.push(imgFilePath);
			
			if (!queActive) startLoadingImgs();
		}
		
		private function startLoadingImgs():void 
		{
			if (imgLoadingQueue.length < 1) return;
			
			queActive = true;
			imgLoading_s1_setup();
		}
		
		private function imgLoading_s1_setup():void 
		{
			ba.clear();
			/* Index is always first element from the top (processed elements are already deleted from queue) */
			/* First element of the queue is always current processed element */
			imgFile.nativePath = imgLoadingQueue[0]; 
			fst.openAsync(imgFile, FileMode.READ); // Stage 2
		}
		
		private function imgLoading_s2_readFile(e:Event):void 
		{
			fst.readBytes(ba, 0, fst.bytesAvailable);
			fst.close();
			ldr.loadBytes(ba); // Stage 3
		}
		
		private function imgLoading_s3_processImg(e:Event):void
		{
			var img:Bitmap = ldr.content as Bitmap;
			var w:int, h:int;
			var processedImgMatrix:BitmapData;
			
			// Calculate image size for box with preserved Aspect Ratio
			if (img.width != img.height)
			{
				var minSide:Number = Math.min(img.width, img.height);
				if (img.width == minSide)
				{
					h = IMG_SQUARE_SIZE * img.height / img.width; // W * scrH / scrW
					w = IMG_SQUARE_SIZE;
				}
				
				else
				{
					w = img.width * IMG_SQUARE_SIZE / img.height; // srcW * H / srcH
					h = IMG_SQUARE_SIZE;
				}
			}
			
			else
			{
				w = h = IMG_SQUARE_SIZE;
			}
			
			// Resize image using Bilinear Interpolation algorithm
			processedImgMatrix = ImageResizer.bilinearIterative(img.bitmapData, w, h, ResizeMath.METHOD_PAN_AND_SCAN);
			img.bitmapData.dispose();
			img = null;
			
			// Crop pixels to fit square
			if (w != h)
			{
				// Calculate crop rect position and dimensions
				var cropRect:Rectangle = new Rectangle();
				if (h < w)
				{
					cropRect.x = (processedImgMatrix.width - IMG_SQUARE_SIZE) / 2;
					cropRect.width = cropRect.height = IMG_SQUARE_SIZE;
				}
				
				else
				
				if (h > w)
				{
					cropRect.width = cropRect.height = IMG_SQUARE_SIZE;
				}
				
				var croppedMatrix:BitmapData = new BitmapData(cropRect.width, cropRect.height);
				croppedMatrix.copyPixels(processedImgMatrix, cropRect, new Point(0, 0));
				processedImgMatrix.dispose();
				processedImgMatrix = croppedMatrix;
			}
			
			/*
			Алгоритм
			> Set final bitmap data (processedImgMatrix) to product image property
			> Dispatch event for items [x] — dispatching of 'update' events goes in opProduct method
			> Check queue. If no more images to process > stop, queActive = false; else > shift queue element and call setup again
			*/
			
			opProduct(checkProductByImgPath(imgLoadingQueue[0]), DataMgr.OP_UPDATE, Product.prop_image, processedImgMatrix, true);
			
			// Check image loading queue
			imgLoadingQueueOutControl();
		}
		
		private function imgLoadingIoError(e:IOErrorEvent):void 
		{
			/*
			Алгоритм
			> Set cor. product image property with bad image sign
			> Remove bad element from queue (shift)
			*/
			var badBdataSign:BitmapData = new BitmapData(1, 1, true, 0);
			opProduct(checkProductByImgPath(imgLoadingQueue[0]), DataMgr.OP_UPDATE, Product.prop_image, badBdataSign, true);
			imgLoadingQueueOutControl();
		}
		
		private function imgLoadingQueueOutControl():void 
		{
			// Remove finished element from queue
			imgLoadingQueue.shift();
			
			// If no more images to process > stop queue
			if (imgLoadingQueue.length < 1) 
			{
				queActive = false; // Stop queue (do nothing)
				trace("Products images loading complete");
			}
			
			// Otherwise > go to 1st step (next element)
			else 
			{
				imgLoading_s1_setup();
			}
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
			newProductEntry.title = "";
			newProductEntry.classID = 0;
			newProductEntry.sku = "";
			newProductEntry.price = 0;
			newProductEntry.weight = 0;
			newProductEntry.imgFile = imgFilePath;
			newProductEntry.note = "";
			
			productsList.push(newProductEntry);
			
			dm.opProduct(newProductEntry.id, DataMgr.OP_ADD, null, newProductEntry as Product);
			addToImgLoadingQueue(imgFilePath);
			
			return newProductEntry;
		}
		
		private function getProductByID(id:int):Product
		{
			for each (var p:Product in productsList) 
			{
				if (p.id == id)
				{
					return p;
				}
			}
			
			throw new Error("No product with ID " + id);
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
			return queActive;
		}
	}
}