package quantum.adr {

	import quantum.adr.processing.ResultObject;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class FormatMgr {

		public static const FRM_NAMES:String = "frmNames";
		public static const FRM_TABLE:String = "frmTable";
		public static const FRM_STR:String = "frmStr";
		public static const FRM_CNT_WH:String = "frmCntWh"; // Canton warehouse

		private static const STRING_DELIM:String = "\t";

		public function FormatMgr():void {

		}

		public function format(resultObj:ResultObject, formatType:String = null):String {
			/*
			Алгоритм
			> if formatType = null > get formatType from Settings
			> else use parameter formatType
			> run it on switch and return formatted string
			*/

			if (resultObj.name == null) {
				trace("Cannot format result. Result Object is null");
				return "";
			}

			var name:String = resultObj.name;
			var country:String = resultObj.country;
			var city:String = resultObj.city;
			var region:String = resultObj.region;
			var postCode:String = resultObj.postCode;
			var addr1:String = resultObj.address1;
			var addr2:String = resultObj.address2;
			var phone:String = resultObj.phone;

			var addrs:String = addr1;
			if (addr2 != null) addrs += ", " + addr2;

			var format:String = formatType;
			var output:String = "";

			switch (format) {
				case FRM_NAMES:
					output += "Recipient: " + name + "\n";
					output += "Address: " + addrs + "\n";
					output += "Country: " + country + "\n";
					output += "City: " + city + "\n";
					output += "Province: " + region + "\n";
					output += "Tel: " + phone + "\n";
					output += "Post code: " + postCode;
					break;

				case FRM_TABLE:
					output += "Airmail for small parcels\n";
					output += name + "\n"; // Recipient
					output += addrs + "\n"; // Address
					output += city + "\n"; // City
					output += region + "\n"; // Province
					output += postCode + "\n"; // Post code
					output += country + "\n"; // Country
					output += phone; // Tel
					break;

				case FRM_STR:
					var jointString:String =
						"Airmail for small parcels" +
						STRING_DELIM +
						name +
						STRING_DELIM +
						addrs +
						STRING_DELIM +
						city +
						STRING_DELIM +
						region +
						STRING_DELIM +
						postCode +
						STRING_DELIM +
						country +
						STRING_DELIM +
						phone;
					output = jointString;
					break;

				case FRM_CNT_WH:

					if (resultObj.sourceAdrLines != null) {

						var tmpArr:Array = resultObj.sourceAdrLines;
						tmpArr.shift();

						var restOfTheAdr:String = "";
						var len:int = tmpArr.length;

						for (var i:int = 0; i < len; i++) {
							restOfTheAdr += (i < len-1) ? tmpArr[i] + "\"&СИМВОЛ(10)&\"" : tmpArr[i];
						}

						output = "=\"Name: " + name + "\"&СИМВОЛ(10)&\"" + "Phone: —" + "\"&СИМВОЛ(10)&\"" + "Addr: " + restOfTheAdr + "\"";

					} else {

						output = "АШИПКА НАСТЁНА АХАХ. ИДИ ПИСАТЬ В ТЕЛЕГРАМ АХАХ";

					}

					break;

				default:
					output = "Ошибка форматирования";
					break;
			}

			return output;
		}

	}

}