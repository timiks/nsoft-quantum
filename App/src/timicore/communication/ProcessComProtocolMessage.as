package timicore.communication 
{
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessComProtocolMessage 
	{
		private var $code:int;
		private var $type:int;
		private var $data:Object; // from JSON
		
		public function get code():int 
		{
			return $code;
		}
		
		public function get type():int 
		{
			return $type;
		}
		
		public function get data():Object 
		{
			return $data;
		}
		
		public function ProcessComProtocolMessage(code:int, type:int, data:Object):void 
		{
			$code = code;
			$type = type;
			$data = data;
		}
	}
}