package quantum.adr.processing {

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class AdrPrcResult {

		public static const STATUS_OK:int = 0;
		public static const STATUS_WARN:int = 1;
		public static const STATUS_ERROR:int = 2;
		public static const STATUS_NOT_PROCESSED:int = 3;

		private var $status:int;
		private var $details:AdrPrcDetails;
		private var $resultObj:AdrResult;

		public function AdrPrcResult(status:int, details:AdrPrcDetails = null, resultObject:AdrResult = null):void {
			this.status = status;
			this.details = details;
			$resultObj = resultObject;
		}

		// PROPERTY: status
		// ================================================================================

		public function get status():int {
			return $status;
		}

		public function set status(value:int):void {
			$status = value;
		}


		// PROPERTY: details
		// ================================================================================

		public function get details():AdrPrcDetails {
			return $details;
		}

		public function set details(value:AdrPrcDetails):void {
			$details = value;
		}

		// PROPERTY: resultObj
		// ================================================================================

		public function get resultObj():AdrResult {
			return $resultObj;
		}

	}

}