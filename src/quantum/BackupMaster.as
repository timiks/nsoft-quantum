package quantum
{
	import com.leeburrows.encoders.AsyncJPGEncoder;
	import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	import flash.display.Bitmap;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BackupMaster
	{
		private const backupDirName:String = "backup"; // Relative to APD directory
		
		private var backupOn:Boolean;
		
		private var main:Main;
		
		public function BackupMaster():void
		{
			main = Main.ins;
			
			// Check backup settings
			backupOn = main.settings.getKey(Settings.backupData);
			
			// Subscribe to data update event
			main.dataMgr.events.addEventListener(DataEvent.DATA_UPDATE, dataUpdated);
		}
		
		private function dataUpdated(e:DataEvent):void
		{
			doBackUp();
		}
		
		public function doBackUp():void
		{
			if (!backupOn)
				return;
			
			main.logRed("Backup check");
			
			var lastBackupTime:Number = main.settings.getKey(Settings.lastBackupTime); // Unix Time (in seconds)
			var currentTime:Number = new Date().time;
			var timeDif:Number = currentTime - lastBackupTime;
			var backupInterval:int = main.settings.getKey(Settings.backupInterval); // In minutes
			var minutesSinceLastBackup:int = millisecondsToMinutes(timeDif);
			
			if (minutesSinceLastBackup < backupInterval)
			{
				main.logRed("Not the time for backup. Last one was " + minutesSinceLastBackup + " min. ago");
				if (Capabilities.isDebugger && !DevSettings.backupAlwaysDoesJob)
					return;
			}
			
			var date:Date = new Date();
			var dtf:DateTimeFormatter = new DateTimeFormatter("ru-RU");
			var dstr:String;
			var dateDirName:String;
			var dataFile:File = main.dataMgr.getDataFileRef();
			
			// Date dir name
			dtf.setDateTimePattern("dd.MM.yy");
			dateDirName = dtf.format(date);
			
			// Date for backup file name
			dtf.setDateTimePattern("dd.MM.yy-HH.mm.ss");
			dstr = dtf.format(date);
			
			// Back up data file
			var dataFileBackup:FileReference =
				File.applicationStorageDirectory.resolvePath(backupDirName + "\\" + dateDirName + "\\" + "data-" + dstr + ".bak");
			dataFile.copyToAsync(dataFileBackup, true);
			
			// Save image
			if (main.settings.getKey(Settings.backupCreateImage))
			{
				var backupImg:File =
					File.applicationStorageDirectory.resolvePath(backupDirName + "\\" + dateDirName + "\\" + "image-" + dstr + ".jpg");
				
				var img:Bitmap = main.stQuantumMgr.grpCnt.image;
				
				var jpegEncoder:AsyncJPGEncoder = new AsyncJPGEncoder(90);
				jpegEncoder.addEventListener(AsyncImageEncoderEvent.COMPLETE, imageEncodeComplete);
				jpegEncoder.addEventListener(AsyncImageEncoderEvent.PROGRESS, imageEncodeProgress);
				jpegEncoder.start(img.bitmapData);
				
				function imageEncodeProgress(e:AsyncImageEncoderEvent):void 
				{
					trace("Backup image encoding progress:", Math.floor(e.percentComplete)+"% complete");
				}
				
				function imageEncodeComplete(e:AsyncImageEncoderEvent):void 
				{
					var fstream:FileStream = new FileStream();
					fstream.openAsync(backupImg, FileMode.WRITE);
					fstream.writeBytes(jpegEncoder.encodedBytes);
					fstream.close();
					
					img.bitmapData.dispose();
					img = null;
					
					jpegEncoder.removeEventListener(AsyncImageEncoderEvent.PROGRESS, imageEncodeProgress);
					jpegEncoder.removeEventListener(AsyncImageEncoderEvent.COMPLETE, imageEncodeComplete);
					
					main.logRed("Backup Image Saved");
				}
			}
			
			// Remember backup time
			main.settings.setKey(Settings.lastBackupTime, new Date().time);
			
			main.logRed("Main Backup Done");
		}
		
		private function millisecondsToMinutes(ms:Number):int
		{
			return int(Math.round(ms / 60 / 1000));
		}
	}
}