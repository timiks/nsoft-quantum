package quantum.backup
{
	import flash.display.Bitmap;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.globalization.DateTimeFormatter;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.Settings;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	import com.leeburrows.encoders.AsyncJPGEncoder;
	import com.leeburrows.encoders.supportClasses.AsyncImageEncoderEvent;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BackupMaster
	{
		private const backupDirName:String = "backup"; // Relative to APD directory
		private const cleanupInterval:int = 20;
		
		private var main:Main;
		
		private var backupDir:File;
		private var tmrImageSave:Timer;
		
		public function BackupMaster():void
		{
			main = Main.ins;
			
			// Reference to backup directory root
			backupDir = File.applicationStorageDirectory.resolvePath(backupDirName);
			
			// Process backup copies
			if (main.settings.getKey(Settings.backupCleanup)) 
			{
				processBackupCopies();
			}
			
			// Subscribe to data save event
			main.dataMgr.events.addEventListener(DataEvent.DATA_SAVE, dataSaved);
		}
		
		private function processBackupCopies():void 
		{
			var dirContents:Array = backupDir.getDirectoryListing();
			
			if (dirContents.length == 0)
				return;
			
			var d:Date = new Date();
			for each (var f:File in dirContents) 
			{
				if (f.isDirectory) 
				{
					var timeLapseMs:Number = d.time - f.creationDate.time;
					if (millisecondsToDays(timeLapseMs) >= cleanupInterval) 
					{
						main.logRed("Deleting old backup: " + f.name);
						f.deleteDirectoryAsync(true);
					}
				}
			}
		}
		
		private function dataSaved(e:DataEvent):void
		{
			if (main.exiting) return;
			doBackUp();
		}
		
		public function doBackUp():void
		{
			if (!main.settings.getKey(Settings.backupData))
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
			var dataFileBackup:FileReference = backupDir.resolvePath(dateDirName + "\\" + "data-" + dstr + ".bak");
			dataFile.copyToAsync(dataFileBackup, true);
			
			// Save image
			if (main.settings.getKey(Settings.backupCreateImage))
			{
				if (tmrImageSave == null) tmrImageSave = new Timer(3000);
				tmrImageSave.addEventListener(TimerEvent.TIMER, checkImageSave);
				tmrImageSave.start();
				
				function checkImageSave(e:TimerEvent):void 
				{
					if (main.stQuantumMgr.grpCnt.loadingActive)
					{
						return;
					}
					else 
					{
						tmrImageSave.stop();
						tmrImageSave.removeEventListener(TimerEvent.TIMER, checkImageSave);
					}
					
					var backupImg:File = backupDir.resolvePath(dateDirName + "\\" + "image-" + dstr + ".jpg");
					
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
						fstream.open(backupImg, FileMode.WRITE);
						fstream.writeBytes(jpegEncoder.encodedBytes);
						fstream.close();
						
						img.bitmapData.dispose();
						img = null;
						
						jpegEncoder.removeEventListener(AsyncImageEncoderEvent.PROGRESS, imageEncodeProgress);
						jpegEncoder.removeEventListener(AsyncImageEncoderEvent.COMPLETE, imageEncodeComplete);
						
						main.logRed("Backup Image Saved");
					}
				}
			}
			
			// Remember backup time
			main.settings.setKey(Settings.lastBackupTime, new Date().time);
			
			main.logRed("Data File Backup Done");
		}
		
		private function millisecondsToMinutes(ms:Number):int
		{
			return int(Math.round(ms / 60 / 1000));
		}
		
		private function millisecondsToDays(ms:Number):int 
		{
			return int(Math.round(ms / 60 / 1000 / 60 / 24));
		}
	}
}