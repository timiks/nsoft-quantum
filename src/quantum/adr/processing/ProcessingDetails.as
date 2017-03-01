package quantum.adr.processing {

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ProcessingDetails {

		public static const ERR_ONE_LINE:String = "Одна строка";
		public static const ERR_UNKNOWN_FORMAT:String = "Неизвестный формат";

		private var $message:String;
		private var $templateType:int;

		public function ProcessingDetails(msg:String, templateType:int = 0):void {
			this.message = msg;
			this.templateType = templateType;
		}

		public function get message():String {
			return $message;
		}

		public function set message(value:String):void {
			$message = value;
		}

		public function get templateType():int {
			return $templateType;
		}

		public function set templateType(value:int):void {
			$templateType = value;
		}

	}

}