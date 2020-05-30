package quantum.adr.processing
{
	import quantum.Main;
	import quantum.adr.processing.ResultObject;
	import quantum.ebay.EbayAddress;
	
	/**
	 * Движок обработки адресов “Addressy” · C 2016 — модуль Квантума
	 * @author Tim Yusupov
	 * @copy ©2015
	 */
	public class ProcessingEngine
	{
		// Version
		private const $version:int = 26;
		
		// Special modes of processing
		/* 1: Process just name and leave source lines as they are */
		public static const PrcSpecialMode1:int = 1;
		/* 2: Get fields from Ebay-processed address */
		public static const PrcSpecialMode2:int = 2;
		
		private var main:Main;
		
		// Data
		private var usRegions:Vector.<Object>;
		private var caRegions:Vector.<Object>;
		private var auRegions:Vector.<Object>;
		private var ndRegions:Vector.<Object>;
		
		private var $resultObj:ResultObject;
		private var addrExamples:Array;
		
		public function ProcessingEngine():void
		{
			//{ region Country Regions Arrays Initialization

			// Штаты США
			usRegions = new Vector.<Object>();
			usRegions.push({ab: "AL", name: "Alabama"});
			usRegions.push({ab: "AK", name: "Alaska"});
			usRegions.push({ab: "AZ", name: "Arizona"});
			usRegions.push({ab: "AR", name: "Arkansas"});
			usRegions.push({ab: "CA", name: "California"});
			usRegions.push({ab: "CO", name: "Colorado"});
			usRegions.push({ab: "CT", name: "Connecticut"});
			usRegions.push({ab: "DE", name: "Delaware"});
			usRegions.push({ab: "DC", name: "District of Columbia"});
			usRegions.push({ab: "FL", name: "Florida"});
			usRegions.push({ab: "GA", name: "Georgia"});
			usRegions.push({ab: "HI", name: "Hawaii"});
			usRegions.push({ab: "ID", name: "Idaho"});
			usRegions.push({ab: "IL", name: "Illinois"});
			usRegions.push({ab: "IN", name: "Indiana"});
			usRegions.push({ab: "IA", name: "Iowa"});
			usRegions.push({ab: "KS", name: "Kansas"});
			usRegions.push({ab: "KY", name: "Kentucky"});
			usRegions.push({ab: "LA", name: "Louisiana"});
			usRegions.push({ab: "ME", name: "Maine"});
			usRegions.push({ab: "MD", name: "Maryland"});
			usRegions.push({ab: "MA", name: "Massachusetts"});
			usRegions.push({ab: "MI", name: "Michigan"});
			usRegions.push({ab: "MN", name: "Minnesota"});
			usRegions.push({ab: "MS", name: "Mississippi"});
			usRegions.push({ab: "MO", name: "Missouri"});
			usRegions.push({ab: "MT", name: "Montana"});
			usRegions.push({ab: "NE", name: "Nebraska"});
			usRegions.push({ab: "NV", name: "Nevada"});
			usRegions.push({ab: "NH", name: "New Hampshire"});
			usRegions.push({ab: "NJ", name: "New Jersey"});
			usRegions.push({ab: "NM", name: "New Mexico"});
			usRegions.push({ab: "NY", name: "New York"});
			usRegions.push({ab: "NC", name: "North Carolina"});
			usRegions.push({ab: "ND", name: "North Dakota"});
			usRegions.push({ab: "OH", name: "Ohio"});
			usRegions.push({ab: "OK", name: "Oklahoma"});
			usRegions.push({ab: "OR", name: "Oregon"});
			usRegions.push({ab: "PA", name: "Pennsylvania"});
			usRegions.push({ab: "RI", name: "Rhode Island"});
			usRegions.push({ab: "SC", name: "South Carolina"});
			usRegions.push({ab: "SD", name: "South Dakota"});
			usRegions.push({ab: "TN", name: "Tennessee"});
			usRegions.push({ab: "TX", name: "Texas"});
			usRegions.push({ab: "UT", name: "Utah"});
			usRegions.push({ab: "VT", name: "Vermont"});
			usRegions.push({ab: "VA", name: "Virginia"});
			usRegions.push({ab: "WA", name: "Washington"});
			usRegions.push({ab: "WV", name: "West Virginia"});
			usRegions.push({ab: "WI", name: "Wisconsin"});
			usRegions.push({ab: "WY", name: "Wyoming"});
			usRegions.push({ab: "PR", name: "Puerto Rico"});
			usRegions.push({ab: "AE", name: "AE"});
			usRegions.push({ab: "AA", name: "AA"});
			usRegions.push({ab: "AP", name: "AP"});

			// Штаты Канады
			caRegions = new Vector.<Object>();
			caRegions.push({ab: "ON", name: "Ontario"});
			caRegions.push({ab: "QC", name: "Quebec"});
			caRegions.push({ab: "NS", name: "Nova Scotia"});
			caRegions.push({ab: "NB", name: "New Brunswick"});
			caRegions.push({ab: "MB", name: "Manitoba"});
			caRegions.push({ab: "BC", name: "British Columbia"});
			caRegions.push({ab: "PE", name: "Prince Edward Island"});
			caRegions.push({ab: "SK", name: "Saskatchewan"});
			caRegions.push({ab: "AB", name: "Alberta"});
			caRegions.push({ab: "NL", name: "Newfoundland and Labrador"});

			// Австралийские регионы
			auRegions = new Vector.<Object>();
			auRegions.push({ab: "NSW", name: "New South Wales"});
			auRegions.push({ab: "QLD", name: "Queensland"});
			auRegions.push({ab: "SA", name: "South Australia"});
			auRegions.push({ab: "TAS", name: "Tasmania"});
			auRegions.push({ab: "VIC", name: "Victoria"});
			auRegions.push({ab: "WA", name: "Western Australia"});

			// Голландские регионы
			ndRegions = new Vector.<Object>();
			ndRegions.push({ab: "DR", name: "Drenthe"});
			ndRegions.push({ab: "FL", name: "Flevoland"});
			ndRegions.push({ab: "FR", name: "Fryslân"});
			ndRegions.push({ab: "GE", name: "Gelderland"});
			ndRegions.push({ab: "GR", name: "Groningen"});
			ndRegions.push({ab: "LI", name: "Limburg"});
			ndRegions.push({ab: "NB", name: "Noord-Brabant"});
			ndRegions.push({ab: "NH", name: "Noord-Holland"});
			ndRegions.push({ab: "OV", name: "Overijssel"});
			ndRegions.push({ab: "UT", name: "Utrecht"});
			ndRegions.push({ab: "ZE", name: "Zeeland"});
			ndRegions.push({ab: "ZH", name: "Zuid-Holland"});
			
			//} endregion

			//{ region Samples

			// Примеры адресов
			addrExamples = [];
			addrExamples.push("Barack Obama\n4245 Swift Ave SW\nGround St. 203\n98367 Miami FL\nСША");
			addrExamples.push("DEANNA SANTILLI[change]\n60 Leech Rd.\nGreenville, PA 16125\nСША");
			addrExamples.push("Jenny Browne\n4245 Swift Ave SW\n98367  Port Orchard , WA\nСША");
			addrExamples.push("Jenny Browne\n4245 Swift Ave SW\n701-1500 Keele St\n98367  Port Orchard , WA\nСША");
			addrExamples.push("Ashley Serrano \n701-1500 Keele St\nHere could be your ad\nYork ON  M6N 5A9\nКанада");
			addrExamples.push("nicole frye[change]\n5394 Longspur Rd\n27349-9888  Snow Camp , NC\nСША");
			addrExamples.push("Christoffer Ström\nNorråsagatan 46B\n57135 Nässjö\nШвеция");
			addrExamples.push("Kate Kelly\n3 Dewvale Road\nO'Halloran Hill, SA 5158\nАвстралия");
			addrExamples.push("Josh Baird\n76 Thornyflat Place\nAyr, South Ayrshire \nKA8 0NE\nUnited Kingdom");
			addrExamples.push("Thomas Dyke\n76 Thornyflat Place\n243 Corndale Muffin\nGreenvich, North Blueberry\nLB2 3UI\nUnited Kingdom");
			addrExamples.push("Frances Schwarzkopf\n30a Beaumont road\nLondon \nW4 5ap\nUnited Kingdom");
			addrExamples.push("Tom Patkowski\n11839-171 Avenue\nEdmonton AB  T5X 6H8\nCanada");
			addrExamples.push("Thiago Branco\nRua Vespasiano, 754 apart. 219\nSão Paulo  - SÃO PAULO\n05044-050\nBrazil");
			addrExamples.push("Lee Kieselbach\n2485 Hill Tout St.\n105\nAbbotsford BC  V2T2P8\nКанада");
			addrExamples.push("Rotem Moshkovitz\nDavid Remez st.36\napartment 5\nTel-Aviv 6219219\nIsrael");
			addrExamples.push("Matthew Whittington\n3236 26 st\nEdmonton Alberta  T6T 1Z3\nКанада");
			addrExamples.push("Tjark Gloe[change]\nBei der alten Mühle 6\nElmshorn, 25335\nGermany");

			//} endregion

			// Result Object Initialization
			$resultObj = new ResultObject();

			// Main link
			main = Main.ins;
		}
		
		/**
		 * Главная функция обработки
		 * @param inputText Входная строка
		 * @return Информация о результате обработки
		 */
		public function process(inputText:String, specialMode:int = 0):ProcessingResult
		{
			var tx:String = inputText;
			var ctrlCharPattern:RegExp = /(\r|\n|\r\n)/;
			
			// ================================================================================
			//
			// Pre-processing Step #1
			//
			// ================================================================================
			
			// Check: empty or one line
			if (tx.length < 1 || tx.search(ctrlCharPattern) == -1)
			{
				processingEnd(ProcessingResult.STATUS_NOT_PROCESSED);
				return new ProcessingResult(ProcessingResult.STATUS_NOT_PROCESSED);
			}
			
			var lines:Array;
			var linesTemp:Array = [];
			var rawSourceLines:Array = [];
			
			// Разделить по строкам
			lines = tx.split(ctrlCharPattern);
			
			var i:int;
			
			// Отчистить от управляющих символов
			for (i = 0; i < lines.length; i++)
			{
				if ((lines[i] as String).search(ctrlCharPattern) == -1)
				{
					linesTemp.push(lines[i]);
					rawSourceLines.push(lines[i]); // Form raw source lines array along the way 
				}
			}
			
			lines = linesTemp;
			linesTemp = [];
			
			// Отчистить от пустых символов
			for (i = 0; i < lines.length; i++)
			{
				if ((lines[i] as String).length != 0 || (lines[i] as String) != "")
					linesTemp.push(lines[i]);
			}
			
			lines = linesTemp;
			linesTemp = null;
			$resultObj.sourceAdrLines = lines;
			
			// ================================================================================
			//
			// Special Modes
			//
			// ================================================================================
			
			if (specialMode != 0) 
			{
				if (specialMode == PrcSpecialMode1) 
				{
					name = processName(lines[0]);
					$resultObj.name = name;
					processingEnd(ProcessingResult.STATUS_OK);
					return new ProcessingResult(
						ProcessingResult.STATUS_OK,
						new ProcessingDetails("Обработано в спец. режиме", tplType, PrcSpecialMode1),
						$resultObj
					);
				}
			}
			
			// ================================================================================
			//
			// Pre-processing Step #2 — Addresses without Country on the last line
			//
			// ================================================================================
			
			var lineX:String
			var lineXObj:Object;
			var lc:uint = lines.length; // Lines Count — число строк
			var theLastLine:String = lines[lines.length-1] as String;
			var theLineBeforeLast:String = lines[lines.length-2] as String;
			var reArr:Array;
			var rePattern:RegExp;
			
			if (lc == 3 || lc == 4 || lc == 5 || lc == 6)
			{
				// [*] NETHERLANDS: Проверка адреса без страны отдельно на последней строчке (Голландия)
				rePattern = /(.+) ?(Netherlands)$/;
				
				reArr = theLastLine.match(rePattern);
				if (reArr != null)
				{
					lines[lines.length-1] = theLastLine.replace(rePattern, "$1"); // Очистить последнюю строку от страны и обновить
					theLastLine = reArr[2]; // New last line
					lines.push(theLastLine); // Добавить новую строку со страной в конец
					lc = lines.length; // Обновить число строк
				}
				
				// [*] POLAND (ПОЛЬША)
				rePattern = /(.+) ?(Poland)$/i;
				
				reArr = theLastLine.match(rePattern);
				if (reArr != null)
				{
					lines[lines.length-1] = theLastLine.replace(rePattern, "$1"); // Очистить последнюю строку от страны и обновить
					theLastLine = reArr[2]; // New last line
					lines.push(theLastLine); // Добавить новую строку со страной в конец
					lc = lines.length; // Обновить число строк
				}
				
				// [*] Американские адреса без страны на конце
				var spcLnObj:Object = processSpecialLine(theLastLine);
				
				if (spcLnObj != null && spcLnObj.region != null)
				{
					// Process America's States
					for (i = 0; i < usRegions.length; i++)
					{
						if (
						(usRegions[i].ab == (spcLnObj.region as String).toUpperCase())
							||
						((usRegions[i].name as String).toUpperCase() == (spcLnObj.region as String).toUpperCase())
						) {
							lines.push("United States"); // Добавить новую строку со страной США в конец
							lc = lines.length; // Обновить число строк
						}
					}
				}
				
				// [*] СИНГАПУР
				rePattern = /^Singapore/i;
				
				reArr = (lines[lines.length-2] as String).match(rePattern);
				
				if (reArr != null)
				{
					lines.pop(); // Delete last line with post code
					lines.push(lines[lines.length-1]); // Add new line with string 'Singapore', which was on the last line before this op.
					var lineBeforeLast:String = lines[lines.length-2] as String;
					lineBeforeLast += " " + theLastLine; // Add post code to the line before last (Singapore)
					lines[lines.length-2] = lineBeforeLast;
					lc = lines.length;
				}
				else
				{
					reArr = theLastLine.match(rePattern);
					if (reArr != null)
					{
						lines.push("Singapore");
						lc = lines.length;
					}
				}
				
				// [*] ЯПОНИЯ / JAPAN
				if ((lines[0] as String).search(/^〒/) != -1 || (lines[lines.length-2] as String).search(/^Japan/i) != -1) 
				{
					var japanTemplateError:Boolean = false;
					var japanPostCodePattern:RegExp = /^〒 ?(.+)/;
					var japanCityAndRegionPattern:RegExp = /(.+), ?(.+)/;
					
					// Japan › Name and Country
					var japanName:String = trimSpaces(lines[lines.length-1]); // Last line
					var japanCountry:String = trimSpaces(lines[lines.length-2]) // Last −1
					
					// Japan › Post code
					reArr = trimSpaces(lines[0] as String).match(japanPostCodePattern);
					if (reArr == null || reArr.length == 0 )
						japanTemplateError = true;
					else 
						var japanPostCode:String = reArr[1];
					
					// · Add hyphen if not present (Format: XXX-XXXX)
					if (japanPostCode.search("-") == -1)
						japanPostCode = japanPostCode.slice(0, 3) + "-" + japanPostCode.slice(3);
					
					// Japan › City and Region
					reArr = (lines[1] as String).match(japanCityAndRegionPattern);
					if (reArr == null || reArr.length == 0 )
					{
						japanTemplateError = true;
					}
					else 
					{
						var japanRegion:String = trimSpaces(reArr[1]);
						var japanCity:String = trimSpaces(reArr[2]);
					}
					
					// Japan › Addr1 and Addr2
					var japanAdr1:String;
					var japanAdr2:String;
					if (lc == 5)
					{
						japanAdr1 = trimSpaces(lines[2]);
					}
					else if (lc == 6)
					{
						 japanAdr1 = trimSpaces(lines[2]);
						 japanAdr2 = trimSpaces(lines[3]);
					}
					
					// Check error
					if (japanTemplateError)
					{
						processingEnd(ProcessingResult.STATUS_ERROR);
						return new ProcessingResult(
							ProcessingResult.STATUS_ERROR,
							new ProcessingDetails("Неверный формат спец. шаблона Японии")
						);
					}
					
					// If OK › Convert to TPL #1
					for (i = 0; i < lc; i++)
						lines.shift();
					
					lines.push(japanName);
					lines.push(japanAdr1);
					if (japanAdr2 != null)
						lines.push(japanAdr2);
					lines.push(japanCity + ", " + japanRegion + " " + japanPostCode);
					lines.push(japanCountry)
					lc = lines.length;
				}
			}
			
			// ================================================================================
			//
			// Processing Initial Step
			//
			// ================================================================================
			
			var name:String;
			var addr1:String;
			var addr2:String;
			var country:String;
			var city:String;
			var region:String;
			var postCode:String;
			var phone:String;
			
			// COUNTRY (Last Line)
			// ================================================================================
			
			switch (lc)
			{
				case 3:
					country = lines[2];
					break;
				case 4:
					country = lines[3];
					break;
				case 5:
					country = lines[4];
					break;
				case 6:
					country = lines[5];
					break;
				case 7:
					country = lines[6];
					break;
				default:
					country = null;
					break;
			}
			
			if (country != null)
			{
				country = processCountry(country);
			}
			
			// No sense to proceed without country
			else
			{
				processingEnd(ProcessingResult.STATUS_NOT_PROCESSED);
				return new ProcessingResult(ProcessingResult.STATUS_NOT_PROCESSED);
			}
				
			// ================================================================================
			//
			// Pre-processing Step #3 — Based on Country; Converting to known templates
			//
			// ================================================================================
			
			// [*] RUSSIA. Converting to TPL #1
			if (country == "Russia" && (lc == 6 || lc == 7)) {
				if (lc == 7) {
					lines[1] += ", " + lines[2]; // Add Address2 to Address1
					lines.splice(2, 1);
				}

				var ruSpl:String = lines[lines.length-4] + ", " + lines[lines.length-3] + " " + lines[lines.length-2];
				lines.pop();
				lines.pop();
				lines.pop();
				lines.pop();
				lines.push(ruSpl);
				lines.push("Russia");

				lc = lines.length; // Обновить число строк
			}

			// [*] CANADA #2. Converting to TPL #2
			if (country == "Canada") {

				rePattern = /^([A-Za-z]{2})\s+/;

				reArr = theLineBeforeLast.match(rePattern); // Предпоследняя строка

				if (reArr != null) {

					var canadianAbbrRegion:String = reArr[1];

					// Process canadian states
					for (i = 0; i < caRegions.length; i++) {
						if (
						(caRegions[i].ab == canadianAbbrRegion.toUpperCase())
							||
						((caRegions[i].name as String).toUpperCase() == canadianAbbrRegion.toUpperCase())
						) {

							theLineBeforeLast = theLineBeforeLast.replace(rePattern, "");
							lines[lines.length-2] = theLineBeforeLast;
							canadianAbbrRegion = trimSpaces(canadianAbbrRegion);
							lines[lines.length-3] = trimSpaces(lines[lines.length-3]);
							lines[lines.length-3] += ", " + canadianAbbrRegion;
							break;

						}
					}

				}

			}
			
			// [*] ITALY. Converting to TPL #1
			if (country == "Italy" && lc >= 5)
			{
				rePattern = /[A-Z]{2}/;
				reArr = theLineBeforeLast.match(rePattern);
				
				if (reArr != null) 
				{
					lines[lines.length-3] += ", " + theLineBeforeLast;
					lines.splice(lines.length-2, 1);
					lc = lines.length;
				}
			}
			
			// [*] IRELAND. Converting to TPL #2 (with 'default' post code)
			if (country == "Ireland") 
			{
				rePattern = /default/i;
				reArr = theLineBeforeLast.match(rePattern);
				
				if (reArr == null) 
				{
					if (rawSourceLines[rawSourceLines.length-2] == "")
						lines.splice(lines.length-1, 0, "default");
					
					lc = lines.length;
				}
			}
			
			// [*] HONG KONG. To TPL #2
			if (country.search(/Hong Kong/i) != -1) 
			{
				lines.push("default");
				lines.push("Hong Kong");
				lc = lines.length;
			}
			
			// ================================================================================
			//
			// PROCESSING
			//
			// ================================================================================
			
			// Identifying template
			// ================================================================================
			switch (lc)
			{
				case 4:
				case 5:
				case 6:
				break;
				default:
					processingEnd(ProcessingResult.STATUS_WARN);
					return new ProcessingResult(
						ProcessingResult.STATUS_WARN,
						new ProcessingDetails(ProcessingDetails.ERR_UNKNOWN_FORMAT)
					);
				break;
			}
			
			// IDENTIFY TEMPLATE
			var tplType:int; // 1 or 2
			var postalCodePattern:RegExp = /^([A-Za-z\d]{1,4}|\d{4,8})[-| ]?([A-Za-z\d]{1,4}|\d{4,8})$/;
			
			if (lc == 4)
			{
				tplType = 1;
			}
			
			else

			if (lc == 5)
			{
				if (String(lines[lines.length-2]).search(postalCodePattern) != -1)
				{
					tplType = 2;
				} 
				else
				{
					tplType = 1;
				}
			}
			
			else

			if (lc == 6)
			{
				tplType = 2;
			}
			
			//trace("Template type is " + tplType);
			
			// NAME (Line 1 — Index 0) and ADDRESS #1 (Line 2 — Index 1)
			// ================================================================================
			
			name = processName(lines[0]);
			addr1 = lines[1];
			
			// #SPECIAL: Processing based on Ebay address info (if info is found, else › regular processing)
			var ebayAddress:EbayAddress = getEbayAddress(addr1);
			if (ebayAddress != null) 
			{
				processFromEbayAddress(ebayAddress, tx);
				
				processingEnd(ProcessingResult.STATUS_OK);
				return new ProcessingResult(
					ProcessingResult.STATUS_OK,
					new ProcessingDetails("Обработано на основе адреса из Ибея", 0, PrcSpecialMode2),
					$resultObj
				);
			}
			
			// === HARD POINT ===
			
			// ADDRESS #2 (TPL #1, TPL #2: Line 3 — Index 2)
			// ================================================================================
			
			if ((tplType == 1 && lc == 5) || (tplType == 2 && lc == 6))
			{
				addr2 = lines[2];
			}
			
			// CITY, REGION & POSTAL CODE
			// ================================================================================
			
			var lastLineIndex:int = lc-1;
			if (tplType == 1)
			{
				lineX = lines[lastLineIndex-1];
				
				lineXObj = processSpecialLine(lineX, country, tplType);
				
				if (lineXObj == null)
				{
					processingEnd(ProcessingResult.STATUS_ERROR);
					return new ProcessingResult(
						ProcessingResult.STATUS_ERROR,
						new ProcessingDetails("Ошибка обработки")
					);
				} 
				else
				{
					city = lineXObj.city;
					region = lineXObj.region;
					postCode = lineXObj.postCode;
				}
			} 
			
			else

			if (tplType == 2)
			{
				postCode = lines[lastLineIndex-1];
				lineX = lines[lastLineIndex-2];
				
				lineXObj = processSpecialLine(lineX, country, tplType);
				
				if (lineXObj == null)
				{
					processingEnd(ProcessingResult.STATUS_ERROR);
					return new ProcessingResult(
						ProcessingResult.STATUS_ERROR,
						new ProcessingDetails("Ошибка обработки")
					);
				} 
				else
				{
					city = lineXObj.city;
					region = lineXObj.region;
				}
			}
			
			// Process region
			if (region != null) 
				region = processRegion(region, country);
			
			// Process postal code
			postCode = processPostalCode(postCode, country);
			
			// Process phone
			phone = getPhone(name, addr1);
			
			// ================================================================================
			//
			// PROCESSING FINAL
			//
			// ================================================================================
			
			resetResultObject();
			$resultObj.name = name;
			$resultObj.country = country;
			$resultObj.city = city;
			$resultObj.region = region != null ? region : country;
			$resultObj.postCode = postCode;
			$resultObj.address1 = addr1;
			$resultObj.address2 = addr2;
			$resultObj.sourceAdr = tx;
			
			if (phone != null)
				$resultObj.phone = phone;
			
			// Успешный финал обработки
			processingEnd(ProcessingResult.STATUS_OK);
			return new ProcessingResult(
				ProcessingResult.STATUS_OK,
				new ProcessingDetails("Обработано", tplType, 0, phone == null ? true : false),
				$resultObj
			);
		}
		
		private function processFromEbayAddress(ebayAddress:EbayAddress, sourceTextAddress:String):void 
		{
			var name:String = processName(ebayAddress.clientName);
			var country:String = ebayAddress.country;
			var region:String = (ebayAddress.region != null && ebayAddress.region != "") ? processRegion(ebayAddress.region, country) : null;
			var city:String = ebayAddress.city;
			var addr1:String = ebayAddress.street1;
			var addr2:String = (ebayAddress.street2 != null && ebayAddress.street2 != "") ? ebayAddress.street2 : null;
			var postCode:String = processPostalCode(ebayAddress.postCode, country);
			var phone:String = (ebayAddress.phone != null && ebayAddress.phone != "") ? ebayAddress.phone : null;
			
			resetResultObject();
			
			$resultObj.name = name;
			$resultObj.country = country;
			$resultObj.region = region != null ? region : country;
			$resultObj.city = city;
			$resultObj.address1 = addr1;
			$resultObj.address2 = addr2;
			$resultObj.postCode = postCode;
			$resultObj.sourceAdr = sourceTextAddress;
			
			if (phone != null)
				$resultObj.phone = phone;
		}

		/**
		 * Вызывается всякий раз при завершении обработки (включая неудачную обработку)
		 */
		private function processingEnd(status:int):void
		{
			// Do some stuff when processing has finished either ok or bad
			// e.g. reset resultObject
			
			if (status != ProcessingResult.STATUS_OK)
				resetResultObject();
		}
		
		private function processSpecialLine(theLine:String, country:String = null, tplType:int = 0):Object
		{
			var retObj:Object = {};
			var reArr:Array;
			
			// Триминг начального и конечного пробела в строке
			if (theLine.search(/^\s(.+)\s$/) != -1)
			{
				// Found both spaces
				theLine = theLine.replace(/^\s(.+)\s$/, "$1");
			} 
			else
			if (theLine.search(/^\s|\s$/) != -1)
			{
				// Found one
				theLine = theLine.replace(/^\s|\s$/, "");
			}
			
			// ================================================================================
			// Cпециальная обработка для отдельных стран
			// ================================================================================
			
			// [*] United Kingdom: comma fix · 23.04.20
			if (country == "United Kingdom") 
			{
				theLine = theLine.replace(/(.*?),*$/, "$1");
				// > Then proceed to common processing
			}
			
			// [*] Canada #1: Custom SPL
			if (country == "Canada")
			{
				reArr = theLine.match(/^([^,]+)  ([^,]+)$/);
				
				if (reArr == null)
				{
					//return null;
				} 
				else
				{
					retObj.postCode = reArr[2];
					var cityAndRegion:String = reArr[1];
					
					reArr = cityAndRegion.match(/^([^,]+) ([A-Z]+)$/);
					
					if (reArr == null)
					{
						//return null;
					} 
					else
					{
						retObj.city = reArr[1];
						retObj.region = reArr[2];
						return retObj;
					}
				}
			}
			
			//{ region [*] UK + Canada (former)
			
			/*
			if (country == "Canada" || country == "United Kingdom")
			{
				reArr = theLine.match(/^([^,]+)  ([^,]+) , ([^,]+)$/);
				
				if (reArr != null)
				{
					retObj.postCode = reArr[1];
					retObj.city = reArr[2];
					retObj.region = reArr[3];
					return retObj;
				}
			}
			*/

			//} endregion
			
			// [*] Brazil: Custom SPL
			if (country == "Brazil")
			{
				reArr = theLine.match(/^([^,]+)  - ([^,]+)$/);
				
				if (reArr == null)
				{
					//return null;
				} 
				else
				{
					retObj.city = reArr[1];
					retObj.region = reArr[2];
					return retObj;
				}
			}
			
			// [*] Netherlands: Custom SPL
			if (country == "Netherlands")
			{
				reArr = theLine.match(/^(\d+ ?[A-Z]{2}) (.+)$/i);
				
				if (reArr == null)
				{
					//return null;
				}
				else
				{
					retObj.postCode = reArr[1];
					retObj.city = reArr[2];
					retObj.region = null;
					return retObj;
				}
			}
			
			// [*] Sweden: Custom SPL
			if (country == "Sweden")
			{
				reArr = theLine.match(/^(\d+[-| ]?\d+) ([^,]+)$/);

				if (reArr == null) {
					//return null;
				} else {
					retObj.postCode = reArr[1];
					retObj.city = reArr[2];
					retObj.region = null;
					return retObj;
				}
			}
			
			// ================================================================================
			// Общая обработка
			// ================================================================================
			
			// === TPL #2 General SPL ===
			
			if (tplType == 2)
			{
				reArr = theLine.match(/^([^,]+),? ?([^,]*)$/);
				
				if (reArr == null)
				{
					return null;
				}
				else
				{
					retObj.city = reArr[1];
					retObj.region = reArr[2] == "" ? null : reArr[2];
					return retObj;
				}
			}
			
			// === TPL #1 General SPL ===
			
			// Обрезать лишние пробелы
			if (theLine.search(/\s{2,}/) != -1)
			{
				theLine = theLine.replace(/\s{2,}/, " ");
			}
			
			// Вся строка, почтовый индекс в конце
			reArr = theLine.match(/^([^,]+) ?,? ([^,]*) (\d+[-| ]?\d+)$/);
			
			if (reArr == null)
			{
				// Вся строка, почтовый индекс в начале
				reArr = theLine.match(/^(\d+[-| ]?\d+) ([^,]+) ?,? ([^,]*)$/);
				
				if (reArr == null)
				{
					//clearResultArea();
					//return null;
					
					var pcBegin:RegExp = /^([A-Z\d]+[-|]?[A-Z\d]+)/; // Индекс в начале (пробелы нельзя)
					reArr = theLine.match(pcBegin);
					
					if (reArr == null)
					{
						var pcEnd:RegExp = /([A-Z\d]+[-|]?[A-Z\d]+)$/; // Индекс в конце (можно с пробелами)
						reArr = theLine.match(pcEnd);
						
						if (reArr == null)
						{
							return null; // END POINT
						}
						else
						{
							// Найден почт. индекс с буквами в конце
							retObj.postCode = reArr[1];
							theLine = theLine.replace(pcEnd, "");
							theLine = theLine.replace(/\s$/, "");
							
							// Город
							reArr = theLine.match(/^([^,]+)/);
							
							if (reArr == null)
							{
								return null; // END POINT
							}
							else
							{
								retObj.city = reArr[1];
								theLine = theLine.replace(/^([^,]+)/, "");
								theLine = theLine.replace(/^\s/, "");
								
								// Регион
								reArr = theLine.match(/,? ?([^,]+)/);
								
								if (reArr == null)
								{
									retObj.region = null;
									return retObj;
								} 
								else
								{
									retObj.region = reArr[1];
									return retObj;
								}
							}
						}
					}
					
					else
					{
						// Найден почт. индекс с буквами в начале
						retObj.postCode = reArr[1];
						theLine = theLine.replace(pcBegin, "");
						theLine = theLine.replace(/^\s/, "");
						
						// Город
						reArr = theLine.match(/^([^,]+)/);
						
						if (reArr == null)
						{
							return null; // END POINT
						}
						else
						{
							retObj.city = reArr[1];
							theLine = theLine.replace(/^([^,]+)/, "");
							theLine = theLine.replace(/^\s/, "");
							
							// Регион
							reArr = theLine.match(/,? ?([^,]+)/);
							
							if (reArr == null)
							{
								retObj.region = null;
								return retObj;
							}
							else
							{
								retObj.region = reArr[1];
								return retObj;
							}
						}
					}
				}
				
				else
				{
					retObj.postCode = reArr[1];
					retObj.city = reArr[2];
					retObj.region = reArr[3];
					return retObj;
				}
			}
			
			else
			{
				retObj.city = reArr[1];
				retObj.region = reArr[2];
				retObj.postCode = reArr[3];
				return retObj;
			}
		}
		
		private function processName(name:String):String
		{
			if (name.search(/\[change\]/) != -1)
				name = name.replace(/\[change\]/, "");
			return name;
		}
		
		private function processCountry(cn:String):String
		{
			switch (cn)
			{
				case "США":
				case "Соединенные Штаты Америки":
				case "USA":
				case "US":
				case "United States of America":
					cn = "United States";
					break;
				
				case "Канада":
					cn = "Canada";
					break;
				
				case "Австралия":
					cn = "Australia";
					break;
				
				case "Испания":
					cn = "Spain";
					break;
				
				case "Франция":
					cn = "France";
					break;
				
				case "Германия":
				case "Deutschland":
					cn = "Germany";
					break;
				
				case "Швеция":
					cn = "Sweden";
					break;
				
				case "Мексика":
					cn = "Mexico";
					break;
				
				case "Швейцария":
					cn = "Switzerland";
					break;
				
				case "Нидерланды":
					cn = "Netherlands"
					break;
				
				case "Великобритания":
				case "UK":
				case "Соединённое королевство":
				case "GB":
				case "Great Britain":
				case "Britain":
					cn = "United Kingdom";
					break;
				
				case "Италия":
					cn = "Italy";
					break;
				
				case "Япония":
					cn = "Japan";
					break;
				
				case "Хорватия":
					cn = "Croatia";
					break;
				
				case "Ирландия":
					cn = "Ireland";
					break;
				
				case "Норвегия":
					cn = "Norway";
					break;
				
				case "Бразилия":
					cn = "Brazil";
					break;
				
				case "Чили":
					cn = "Chile";
					break;
				
				case "Португалия":
					cn = "Portugal";
					break;
				
				case "Финляндия":
					cn = "Finland";
					break;
				
				default:
					break;
			}
			return cn;
		}
		
		private function processRegion(rg:String, country:String):String
		{
			function iterateRegions(list:Vector.<Object>):void
			{
				for (var i:int = 0; i < list.length; i++)
				{
					if (list[i].ab == rg.toUpperCase())
					{
						rg = list[i].name;
						break;
					}
				}
			}
			
			if (rg.search(/NOT[- ]?PROVIDED/i) != -1)
			{
				rg = null;
			}
			else
			if (country == "United States")
			{
				// Process US states
				iterateRegions(usRegions);
			} 
			else
			if (country == "Canada")
			{
				// Process canadian regions
				iterateRegions(caRegions);
			}
			else
			if (country == "Australia")
			{
				// Process australian regions
				iterateRegions(auRegions);
			}
			
			return rg;
		}
		
		private function processPostalCode(postCode:String, country:String):String 
		{
			if (country == "Switzerland") 
				postCode = postCode.replace(/^CH-/, "");
			else
			if (country == "United Kingdom" && postCode.search(/^[A-Z\d]{6}$/i) != -1)
				postCode = postCode.slice(0, 3) + " " + postCode.slice(3);
			else
			if (country == "United Kingdom" && postCode.search(/^[A-Z\d]{7}$/i) != -1)
				postCode = postCode.slice(0, 4) + " " + postCode.slice(4);
			else
			if (country == "Poland" && postCode.search("-") == -1)
				postCode = postCode.slice(0, 2) + "-" + postCode.slice(2);
			else
			if (country == "Canada" && postCode.search(/^[A-Z\d]{6}$/i) != -1)
				postCode = postCode.slice(0, 3) + " " + postCode.slice(3);
			else
			if (country == "Netherlands" && postCode.search(/^\d{4}[A-Z]{2}/i) != -1)
				postCode = postCode.slice(0, 4) + " " + postCode.slice(4);
			
			return postCode;
		}
		
		private function getPhone(adrName:String, adrLine1:String):String 
		{
			return main.ebayOrders.getAdrPhone(adrName, adrLine1); // [!] May return null
		}
		
		private function getEbayAddress(adrLine1:String):EbayAddress 
		{
			return main.ebayOrders.getEbayAddress(adrLine1); // [!] May return null
		}
		
		private function resetResultObject():void
		{
			$resultObj.reset();
		}
		
		private function trimSpaces(str:String):String
		{
			var ret:String = str.replace(/^\s*(.*?)\s*$/, "$1");
			return ret;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function setOwnAddress():void
		{
			resetResultObject();
			$resultObj.name = "Ponomareva Anastasia Alexandrovna";
			$resultObj.address1 = "5-5-33";
			$resultObj.city = "Nyagan";
			$resultObj.region = "HMAO";
			$resultObj.postCode = "628181";
			$resultObj.country = "Russia";
		}
		
		public function getRandomAddress():String
		{
			return addrExamples[Math.round(Math.random() * 10)] as String;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		/**
		 * Объект с отдельными полями результата
		 */
		public function get resultObject():ResultObject
		{
			return $resultObj;
		}
		
		/**
		 * Версия движка
		 */
		public function get version():String
		{
			return String($version);
		}
	}
}