package quantum.product.images 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import quantum.data.DataMgr;
	import quantum.gui.elements.GroupItem;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	import sk.yoz.image.ImageResizer;
	import sk.yoz.math.ResizeMath;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ImageLoader 
	{
		[Embed(source = "/../lib/graphics/missing-file-red-icon.png")]
		private static var MissingFilePic:Class; // 200 x 200
		
		public static const IMG_SQUARE_SIZE:int = GroupItem.SQUARE_SIZE;
		
		private var pm:ProductsMgr
		private var cacheMgr:ImageCacheMgr;
		
		private var fst:FileStream;
		private var ldr:Loader;
		private var imgFile:File; // Current image file being processed
		private var ba:ByteArray;
		private var imgLoadingQueue:Vector.<String>;
		private var queActive:Boolean;
		private var loadingStartTime:int;
		
		public function ImageLoader(productsMgr:ProductsMgr, imgCacheMgr:ImageCacheMgr):void
		{
			pm = productsMgr;
			cacheMgr = imgCacheMgr;
			init();
		}
		
		public function init():void 
		{
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
		
		public function registerImageFileForLoading(imgFilePath:String):void 
		{
			imgLoadingQueue.push(imgFilePath);
			
			if (!queActive) startLoadingImgs();
		}
		
		private function startLoadingImgs():void 
		{
			if (imgLoadingQueue.length < 1) return;
			
			loadingStartTime = getTimer();
			trace("Loading start time:", loadingStartTime / 1000);
			
			queActive = true;
			imgLoading_s1_setup();
		}
		
		// ================================================================================
		
		private function imgLoading_s1_setup():void 
		{
			ba.clear();
			
			/* Index is always first element from the top (processed elements are already deleted from queue) */
			/* First element of the queue is always current processed element */
			imgFile.nativePath =
				cacheMgr.getCachedImgFilePath(imgLoadingQueue[0]) != null ?
					cacheMgr.getCachedImgFilePath(imgLoadingQueue[0]) : imgLoadingQueue[0];
					
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
				pm.opProduct(pm.checkProductByImgPath(imgPathQueue), DataMgr.OP_UPDATE, Product.prop_image, img.bitmapData, true);
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
			
			var pid:int = pm.checkProductByImgPath(imgPathQueue);
			pm.opProduct(pid, DataMgr.OP_UPDATE, Product.prop_image, processedImgMatrix, true);
			
			// Save mini-pic in cache
			cacheMgr.saveImageInCache(processedImgMatrix, imgPathQueue, imgFile.size);
			
			// Check image loading queue
			imgLoadingQueueOutControl();
		}
		
		private function imgLoadingIoError(e:IOErrorEvent):void 
		{
			var missingFilePic:Bitmap = new MissingFilePic();
			
			var resizedPixels:BitmapData =
				ImageResizer.bilinearIterative(missingFilePic.bitmapData,
				IMG_SQUARE_SIZE, IMG_SQUARE_SIZE, ResizeMath.METHOD_PAN_AND_SCAN);
				
			missingFilePic.bitmapData.dispose();
			
			pm.opProduct(pm.checkProductByImgPath(imgLoadingQueue[0]), DataMgr.OP_UPDATE, Product.prop_image, resizedPixels, true);
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
		// PROPERTIES
		// ================================================================================
		
		public function get loadingActive():Boolean
		{
			return queActive;
		}
	}
}