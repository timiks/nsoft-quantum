package quantum.backup 
{
	import flash.display.Bitmap;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class BackupSnapshot 
	{
		private var $dataFileString:String;
		private var $groupsImage:Bitmap;
		
		public function BackupSnapshot(dataFileString:String, groupsImage:Bitmap):void 
		{
			$dataFileString = dataFileString;
			$groupsImage = groupsImage;
		}
		
		public function get dataFileString():String 
		{
			return $dataFileString;
		}
		
		public function get groupsImage():Bitmap 
		{
			return $groupsImage;
		}
	}
}