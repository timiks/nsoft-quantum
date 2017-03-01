package quantum {

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class Warehouse {

		public static const BEIJING:String = "Beijing";
		public static const CANTON:String = "Canton";

		public function Warehouse():void {

		}

		public static function getRussianTitle(whID:String):String {
			switch (whID) {
				case BEIJING:
					return "Пекин";
					break;

				case CANTON:
					return "Кантон";
					break;

				default:
					return "АШИПКА";
					break;
			}
		}

	}

}