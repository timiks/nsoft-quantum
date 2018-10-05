package quantum.product 
{
	import com.adobe.crypto.MD5;
	import com.leeburrows.encoders.AsyncJPGEncoder;
	import com.leeburrows.encoders.AsyncPNGEncoder;
	import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
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
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import quantum.Main;
	import quantum.data.DataMgr;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	import quantum.gui.SquareItem;
	import sk.yoz.image.ImageResizer;
	import sk.yoz.math.ResizeMath;
	import tim.as3lib.TimUtils;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProductsMgr 
	{
		[Embed(source = "/../lib/graphics/missing-file-red-icon.png")]
		private var MissingFilePic:Class; // 200 x 200
		
		private const IMG_SQUARE_SIZE:int = SquareItem.SQUARE_SIZE;
		private const imgCacheDirName:String = "cache";
		
		private var $events:EventDispatcher;
		
		private var main:Main;
		private var dm:DataMgr; // Shortcut for DataMgr
		
		private var idCounter:int;
		private var productsList:Vector.<Product>;
		
		private var fst:FileStream;
		private var ldr:Loader;
		private var imgFile:File; // Current image file being processed
		private var ba:ByteArray;
		private var imgLoadingQueue:Vector.<String>;
		private var queActive:Boolean;
		private var imgFileCacheList:Dictionary;
		private var cacheDir:File;
		private var cacheDirFiles:Array;
		private var jpegEncoder:AsyncJPGEncoder;
		private var pngEncoder:AsyncPNGEncoder;
		private var loadingStartTime:int;
		
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
			
			if (Capabilities.isDebugger && !DevSettings.loadProductsImages) return;
			
			var p:Product;
			
			// Cache
			cacheDir = File.applicationStorageDirectory.resolvePath(imgCacheDirName);
			
			if (!cacheDir.exists)
				cacheDir.createDirectory();
			
			cacheDirFiles = cacheDir.getDirectoryListing();
			imgFileCacheList = new Dictionary(true); // [!]
			
			var cacheFileNamePattern:RegExp = /^(\d+)-(.+)-(\d+)-(\d+)/;
			var rea:Array;
			var originalFile:File = new File();
			if (cacheDirFiles.length != 0) 
			{
				for each (var f:File in cacheDirFiles) 
				{
					if (f.name.search(cacheFileNamePattern) == -1)
					{
						f.deleteFileAsync();
						continue;
					}
					
					/*
					1 — Product ID
					2 — Original image file path hash
					3 — Original image file size in bytes
					4 — Square size of the cached image file
					*/
					rea = f.name.match(cacheFileNamePattern);
					
					if (int(rea[4]) != IMG_SQUARE_SIZE) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					p = null;
					p = getProductByID(int(rea[1]));
					
					if (p == null) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					if (MD5.hash(p.imgFile) != TimUtils.trimSpaces(rea[2])) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					originalFile.nativePath = p.imgFile;
					
					if (!originalFile.exists) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					if (originalFile.size != int(rea[3])) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					imgFileCacheList[p.imgFile] = f.nativePath;
				}
			}
			
			// Shuffle images list (for loading in random order)
			var imgList:Array = [];
			for each (p in productsList) 
			{
				imgList.push(p.imgFile);
			}
			
			TimUtils.shuffleArray(imgList);
			
			// Initial load and process of all product images
			for each (var img:String in imgList) 
			{
				addToImgLoadingQueue(img);
			}
			
			p = null;
			img = null;
			imgList = null;
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
			
			loadingStartTime = getTimer();
			
			queActive = true;
			imgLoading_s1_setup();
		}
		
		private function imgLoading_s1_setup():void 
		{
			ba.clear();
			/* Index is always first element from the top (processed elements are already deleted from queue) */
			/* First element of the queue is always current processed element */
			imgFile.nativePath =
				imgFileCacheList[imgLoadingQueue[0]] != null ? imgFileCacheList[imgLoadingQueue[0]] : imgLoadingQueue[0];
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
			var imgPathQueue:String = imgLoadingQueue[0];
			
			// Cache
			if (img.bitmapData.width == IMG_SQUARE_SIZE) 
			{
				opProduct(checkProductByImgPath(imgPathQueue), DataMgr.OP_UPDATE, Product.prop_image, img.bitmapData, true);
				imgLoadingQueueOutControl();
				return;
			}
			
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
			
			var pid:int = checkProductByImgPath(imgPathQueue);
			opProduct(pid, DataMgr.OP_UPDATE, Product.prop_image, processedImgMatrix, true);
			
			// Save cache
			if (imgPathQueue.search(/.png$/i) != -1) 
			{
				pngEncoder = new AsyncPNGEncoder();
				pngEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, imgLoading_s4_saveCache);
				pngEncoder.start(processedImgMatrix) // Stage 4: PNG
			}
			else 
			{
				jpegEncoder = new AsyncJPGEncoder(100);
				jpegEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, imgLoading_s4_saveCache);
				jpegEncoder.start(processedImgMatrix); // Stage 4: JPG
			}
		}
		
		private function imgLoading_s4_saveCache(e:AsyncImageEncoderEvent):void 
		{
			jpegEncoder.removeEventListener(AsyncImageEncoderEvent.COMPLETE, imgLoading_s4_saveCache);
			
			var cacheImageFile:File = new File();
			var pid:int = checkProductByImgPath(imgFile.nativePath);
			var isPNG:Boolean = (imgFile.nativePath.search(/.png$/i) != -1);
			
			cacheImageFile = cacheDir.resolvePath(
				String(pid) + "-" + 
				MD5.hash(imgFile.nativePath) + "-" + 
				imgFile.size.toString() + "-" +
				String(IMG_SQUARE_SIZE) + (isPNG ? ".png" : ".jpg"));
			
			fst.open(cacheImageFile, FileMode.WRITE);
			isPNG ? fst.writeBytes(pngEncoder.encodedBytes) : fst.writeBytes(jpegEncoder.encodedBytes);
			fst.close();
			trace("Cache image saved.", cacheImageFile.nativePath);
			
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
			var missingFilePic:Bitmap = new MissingFilePic();
			var resizedPixels:BitmapData =
				ImageResizer.bilinearIterative(missingFilePic.bitmapData,
				IMG_SQUARE_SIZE, IMG_SQUARE_SIZE, ResizeMath.METHOD_PAN_AND_SCAN);
			missingFilePic.bitmapData.dispose();
			
			opProduct(checkProductByImgPath(imgLoadingQueue[0]), DataMgr.OP_UPDATE, Product.prop_image, resizedPixels, true);
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
				trace("Duration:", (getTimer()-loadingStartTime)/1000+" s");
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
			return queActive;
		}
	}
}