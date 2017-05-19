package quantum {

	import flash.filesystem.File;
	import flash.globalization.DateTimeFormatter;
	import flash.net.FileReference;
	import quantum.events.DataEvent;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BackupMaster {

		private const backupDirName:String = "backup"; // Relative to APD directory

		private var backupOn:Boolean;

		private var main:Main;

		public function BackupMaster():void {

			main = Main.ins;

			// Check backup settings
			backupOn = main.settings.getKey(Settings.backupData);

			// Subscribe to data update event
			main.dataMgr.events.addEventListener(DataEvent.DATA_UPDATE, dataUpdated);

		}

		private function dataUpdated(e:DataEvent):void {

			backUpData();

		}

		public function backUpData():void {

			if (!backupOn) return;

			main.logRed("Backup check");

			var lastBackupTime:Number = main.settings.getKey(Settings.lastBackupTime); // Unix Time (in seconds)
			var currentTime:Number = new Date().time;
			var timeDif:Number = currentTime - lastBackupTime;
			var backupInterval:int = main.settings.getKey(Settings.backupInterval); // In minutes
			var minutesSinceLastBackup:int = millisecondsToMinutes(timeDif);

			if (minutesSinceLastBackup < backupInterval) {
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
			var dataFileBackup:FileReference =
				File.applicationStorageDirectory.resolvePath(backupDirName + "\\" + dateDirName + "\\" + "data-"+dstr+".bak");
			dataFile.copyTo(dataFileBackup, true);

			// Remember backup time
			main.settings.setKey(Settings.lastBackupTime, new Date().time);

			main.logRed("Backup Done");

		}

		private function millisecondsToMinutes(ms:Number):int {

			return int(Math.round(ms / 60 / 1000));

		}

		private function minutesToMilliseconds(minutes:int):Number {

			return minutes * 60 * 1000;

		}

	}

}