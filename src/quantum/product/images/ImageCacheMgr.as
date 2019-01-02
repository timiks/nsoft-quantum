package quantum.product.images 
{
	import com.adobe.crypto.MD5;
	import flash.display.BitmapData;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	import tim.as3lib.TimUtils;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ImageCacheMgr 
	{
		private const imgCacheDirName:String = "cache";
		
		private var pm:ProductsMgr;
		
		private var cacheDir:File;
		private var cacheDirFiles:Array;
		private var imgFileCacheList:Dictionary;
		private var cacheSaveTask:ImageCacheSaveTask;
		
		public function ImageCacheMgr(productsMgr:ProductsMgr):void 
		{
			pm = productsMgr;
			init();
		}
		
		public function init():void 
		{
			cacheDir = File.applicationStorageDirectory.resolvePath(imgCacheDirName);
			
			if (!cacheDir.exists)
				cacheDir.createDirectory();
			
			cacheDirFiles = cacheDir.getDirectoryListing();
			imgFileCacheList = new Dictionary(true);
			cacheSaveTask = new ImageCacheSaveTask(pm, cacheDir);
			
			var cacheFileNamePattern:RegExp = /^(\d+)-(.+)-(\d+)-(\d+)/;
			var rea:Array;
			var originalFile:File = new File();
			var p:Product;
			
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
					
					if (int(rea[4]) != ImageLoader.IMG_SQUARE_SIZE) 
					{
						f.deleteFileAsync();
						continue;
					}
					
					p = null;
					p = pm.getProductByID(int(rea[1]));
					
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
		}
		
		public function getCachedImgFilePath(originalImgFilePath:String):String 
		{
			return imgFileCacheList[originalImgFilePath];
		}
		
		public function saveImageInCache(pixels:BitmapData, originalImgFilePath:String, originalImgFileBytesCount:int):void 
		{
			cacheSaveTask.addTask(pixels, originalImgFilePath, originalImgFileBytesCount);
		}
	}
}