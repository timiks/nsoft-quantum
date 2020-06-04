package timicore 
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessManager 
	{
		protected var childProcessCtrl:ChildProcessController;
		protected var processFile:File;
		protected var $events:EventDispatcher;
		protected var $processFileNotFound:Boolean;
		
		public function ProcessManager(processFile:File):void 
		{
			this.processFile = processFile;
		}
		
		public function init():void 
		{
			$events = new EventDispatcher();
			
			childProcessCtrl =
				new ChildProcessController(processFile);
			childProcessCtrl.init();
			
			if (!childProcessCtrl.processFileIsOk)
			{
				$processFileNotFound = true;
				return;
			}
		}
		
		public function get processFileNotFound():Boolean 
		{
			return $processFileNotFound;
		}
		
		public function get events():EventDispatcher
		{
			return $events;
		}
	}
}