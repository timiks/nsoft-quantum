package quantum.product.images 
{
	import com.adobe.crypto.MD5;
	import com.leeburrows.encoders.AsyncJPGEncoder;
	import com.leeburrows.encoders.AsyncPNGEncoder;
	import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import quantum.product.ProductsMgr;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ImageCacheSaveTask 
	{
		private const imagesWithAlphaFileExtensionPattern:RegExp = /\.(png|gif)$/i;
		
		private var pm:ProductsMgr;
		
		private var fst:FileStream;
		private var cacheDir:File;
		private var cacheImgFile:File;
		private var jpegEncoder:AsyncJPGEncoder;
		private var pngEncoder:AsyncPNGEncoder;
		
		private var taskQueue:Vector.<Object>;
		private var currentTask:Object;
		private var queActive:Boolean;
		
		public function ImageCacheSaveTask(productsMgr:ProductsMgr, cacheDir:File):void 
		{
			pm = productsMgr;
			this.cacheDir = cacheDir;
			
			init();
		}
		
		private function init():void 
		{
			fst = new FileStream();
			taskQueue = new Vector.<Object>();
			pngEncoder = new AsyncPNGEncoder();
			jpegEncoder = new AsyncJPGEncoder(100);
		}
		
		public function addTask(pixels:BitmapData, originalImgFilePath:String, originalImgFileBytesCount:int):void 
		{
			taskQueue.push
			({
				pixels: pixels, 
				originalImgFilePath: originalImgFilePath, 
				originalImgFileBytesCount: originalImgFileBytesCount
			});
			
			if (!queActive) startQueue();
		}
		
		private function startQueue():void 
		{
			if (taskQueue.length < 1) return;
			
			queActive = true;
			s1_setup();
		}
		
		private function s1_setup():void 
		{
			currentTask = taskQueue[0];
			
			if (currentTask.originalImgFilePath.search(imagesWithAlphaFileExtensionPattern) != -1) 
			{
				// PNG
				pngEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, s2_saveCachedImage);
				pngEncoder.start(currentTask.pixels);
			}
			else 
			{
				// JPG
				jpegEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, s2_saveCachedImage);
				jpegEncoder.start(currentTask.pixels);
			}
		}
		
		private function s2_saveCachedImage(e:AsyncImageEncoderEvent):void 
		{
			var pid:int = pm.checkProductByImgPath(currentTask.originalImgFilePath);
			var isImageWithAlphaSupport:Boolean = (currentTask.originalImgFilePath.search(imagesWithAlphaFileExtensionPattern) != -1);
			
			(isImageWithAlphaSupport ? pngEncoder : jpegEncoder).removeEventListener(AsyncImageEncoderEvent.COMPLETE, s2_saveCachedImage);
			
			cacheImgFile = cacheDir.resolvePath(
				String(pid) + "-" + 
				MD5.hash(currentTask.originalImgFilePath) + "-" + 
				currentTask.originalImgFileBytesCount.toString() + "-" +
				String(ImageLoader.IMG_SQUARE_SIZE) + 
				(isImageWithAlphaSupport ? ".png" : ".jpg"));
			
			fst.addEventListener(Event.COMPLETE, taskDone);
			fst.openAsync(cacheImgFile, FileMode.WRITE);
			fst.writeBytes((isImageWithAlphaSupport ? pngEncoder : jpegEncoder).encodedBytes);
			fst.close();
			taskDone();
		}
		
		private function taskDone():void 
		{
			trace("Cache image saved:", cacheImgFile.nativePath);
			
			fst.close();
			fst.removeEventListener(Event.COMPLETE, taskDone);
			cacheImgFile = null;
			
			queueOutControl();
		}
		
		private function queueOutControl():void 
		{
			// Remove finished element from queue
			taskQueue.shift();
			
			// If no more images to process > stop queue
			if (taskQueue.length < 1) 
			{
				queActive = false; // Stop queue (do nothing)
				currentTask = null;
				trace("Image cache saving task complete");
			}
			
			// Otherwise > go to 1st step (next element)
			else 
			{
				s1_setup();
			}
		}
	}
}