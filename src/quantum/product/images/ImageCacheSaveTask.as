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
		private var pm:ProductsMgr;
		
		private var fst:FileStream;
		private var cacheDir:File;
		private var cacheImgFile:File;
		private var originalImgFilePath:String;
		private var originalImgFileBytesCount:int
		private var jpegEncoder:AsyncJPGEncoder;
		private var pngEncoder:AsyncPNGEncoder;
		
		public function ImageCacheSaveTask(
			productsMgr:ProductsMgr, 
			cacheDir:File, pixels:BitmapData, 
			originalImgFilePath:String,
			originalImgFileBytesCount:int):void 
		{
			pm = productsMgr;
			this.cacheDir = cacheDir;
			this.originalImgFilePath = originalImgFilePath;
			this.originalImgFileBytesCount = originalImgFileBytesCount;
			
			fst = new FileStream();
			
			if (originalImgFilePath.search(/.png$/i) != -1) 
			{
				// PNG
				pngEncoder = new AsyncPNGEncoder();
				pngEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, saveCachedImage);
				pngEncoder.start(pixels);
			}
			else 
			{
				// JPG
				jpegEncoder = new AsyncJPGEncoder(100);
				jpegEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, saveCachedImage);
				jpegEncoder.start(pixels);
			}
		}
		
		private function saveCachedImage(e:AsyncImageEncoderEvent):void 
		{
			var pid:int = pm.checkProductByImgPath(originalImgFilePath);
			var isPNG:Boolean = (originalImgFilePath.search(/.png$/i) != -1);
			
			(isPNG ? pngEncoder : jpegEncoder).removeEventListener(AsyncImageEncoderEvent.COMPLETE, saveCachedImage);
			
			cacheImgFile = cacheDir.resolvePath(
				String(pid) + "-" + 
				MD5.hash(originalImgFilePath) + "-" + 
				originalImgFileBytesCount.toString() + "-" +
				String(ImageLoader.IMG_SQUARE_SIZE) + 
				(isPNG ? ".png" : ".jpg"));
			
			fst.addEventListener(Event.COMPLETE, taskDone);
			fst.openAsync(cacheImgFile, FileMode.WRITE);
			fst.writeBytes((isPNG ? pngEncoder : jpegEncoder).encodedBytes);
			taskDone(null);
		}
		
		private function taskDone(e:Event):void 
		{
			trace("Cache image saved.", cacheImgFile.nativePath);
			
			fst.close();
			fst.removeEventListener(Event.COMPLETE, taskDone);
			fst = null;
			cacheDir = null;
			cacheImgFile = null;
			originalImgFilePath = null;
			jpegEncoder = null;
			pngEncoder = null;
		}
	}
}