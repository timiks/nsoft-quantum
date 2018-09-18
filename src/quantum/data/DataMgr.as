package quantum.data
{
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.dev.DevSettings;
	import quantum.events.DataEvent;
	import quantum.gui.ItemsGroup;
	import quantum.gui.SquareItem;
	import quantum.product.Product;
	import quantum.warehouse.Warehouse;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class DataMgr
	{
		public static const OP_READ:String = "read"; // Read value of individual fields of a record
		public static const OP_ADD:String = "add"; // Add new record to base
		public static const OP_REMOVE:String = "rem"; // Remove record from base
		public static const OP_UPDATE:String = "upd"; // Update value of individual fields of a record
		public static const OP_CHANGE_ORDER:String = "changeOrder";
		public static const OP_SWAP_ELEMENTS:String = "swap";
		
		private static const dataFileVersion:int = 3;
		
		private var main:Main;
		
		private var dataXml:XML;
		private var dataFile:File;
		private var fstream:FileStream;
		
		private var tmrSaveDelay:Timer;
		private var loaded:Boolean = false;
		
		private var $events:EventDispatcher;
		
		public function DataMgr():void {}
		
		public function load():void
		{
			/*
			Алгоритм
			> check Data File existence in AppData dir
			> 	* if found > parse XML into dataXml object; check for errors
			>	* if not found > create dataXml object with default sets and create Data File
			*/
			
			main = Main.ins;
			
			$events = new EventDispatcher();
			dataFile = File.applicationStorageDirectory.resolvePath("data.xml");
			fstream = new FileStream();
			
			// Data file isn't found
			if (!dataFile.exists)
			{
				trace("Data File not found");
				initDefXmlAndCreateFile();
				loaded = true;
			}
			
			// Data file is found
			else
			{
				trace("Data File found: " + dataFile.nativePath);
				
				fstream.open(dataFile, FileMode.READ);
				var xmlString:String = fstream.readUTFBytes(fstream.bytesAvailable);
				fstream.close();
				
				// Empty file
				if (xmlString == "")
				{
					initDefXmlAndCreateFile();
				}
				
				// Alright
				else
				{
					// Construct XML tree from data file
					dataXml = new XML(xmlString);
					
					// Do some checks and changes
					if (dataXml.@appVersion != main.version)
						dataXml.@appVersion = main.version;
					
					// If data file version not found > add it
					var dfv:String = dataXml.@dataFileVersion;
					if (dfv == "" || dfv == null)
						dataXml.@dataFileVersion = String(dataFileVersion);
					
					// {Here should be version check of loaded data file and
					// transforming loaded format to actual version format, if differ}
					
					// [!] Separate function or module needed
					
					// Data File v1 → v2
					if (int(dfv) < 2)
					{
						if (dataXml.notes == undefined)
						{
							dataXml.prependChild(<notes/>);
						}
					}
					
					// [!][~ #TEST THIS ~]
					// Data File v2 → v3
					if (int(dfv) < 3) 
					{
						var grp:XML;
						var itm:XML;
						var noteEntry:XML;
						var xmlQuery:XMLList;
						
						// Stage 1
						dataXml.prependChild(<groups/>);
						for each (grp in dataXml.itemsGroup)
						{
							dataXml.groups.appendChild(grp);
							delete dataXml.children()[grp.childIndex()];
						}
						
						// Stage 2
						var productsNode:XML = dataXml.prependChild(<products/>);
						var singleProductNode:XML;
						var productIdCounter:int = 1;
						for each (grp in dataXml.groups.itemsGroup) 
						{
							for each (itm in grp.item) 
							{
								xmlQuery = productsNode.product.(@imgFile == itm.@imgPath)
								
								if (xmlQuery.length() == 0) 
								{
									singleProductNode = <product/>;
									singleProductNode.@id = productIdCounter++;
									singleProductNode.@title = "";
									singleProductNode.@classID = "";
									singleProductNode.@sku = "";
									singleProductNode.@price = "0";
									singleProductNode.@weight = "0";
									singleProductNode.@imgFile = itm.@imgPath;
									singleProductNode.@note = "";
									productsNode.appendChild(singleProductNode);
									
									itm.@productID = singleProductNode.@id;
									delete itm.@imgPath;
								}
								
								else
								{
									if (xmlQuery.length() == 1)
									{
										singleProductNode = xmlQuery[0];
										itm.@productID = singleProductNode.@id;
										delete itm.@imgPath;
									}
									else
									{
										throw new Error("Product should be unique");
									}
								}
							}
						}
						productsNode.@idCounter = productIdCounter;
						
						// Stage 3: Notes
						for each (noteEntry in dataXml.notes.itemNote) 
						{
							xmlQuery = productsNode.product.(@imgFile == noteEntry.@img);
							if (xmlQuery.length() == 1)
							{
								singleProductNode = xmlQuery[0];
								singleProductNode.@note = noteEntry.@text;
								delete dataXml.notes.children()[noteEntry.childIndex()];
							}
							else
							{
								throw new Error("Product should be unique");
							}
						}
						delete dataXml.children()[dataXml.notes.childIndex()];
					}
					
					// Updating data file version if differs
					if (dataXml.@dataFileVersion != dataFileVersion)
						dataXml.@dataFileVersion = dataFileVersion
				}
				
				// [To-Do Here ↓]: Errors check
				
				loaded = true;
			}
		}
		
		private function initDefXmlAndCreateFile(createFile:Boolean = true):void
		{
			// Default XML
			dataXml = <quantumData/>;
			dataXml.@appVersion = main.version;
			dataXml.@dataFileVersion = String(dataFileVersion);
			
			// DF v2 feature (not actual in v3+)
			/* dataXml.appendChild(<notes/>); */
			
			// [!][~ #TEST THIS ~]
			// DF v3 features
			dataXml.appendChild(<products/>);
			dataXml.appendChild(<groups/>);
			
			if (!createFile) return;
			
			saveFile();
		}
		
		/**
		 * Вызывать всякий раз при изменении данных, чтобы изменения можно было сохранить на диск
		 */
		private function dataUpdate(delay:int = 3000):void
		{
			if (tmrSaveDelay == null)
			{
				tmrSaveDelay = new Timer(delay, 1);
				tmrSaveDelay.addEventListener(TimerEvent.TIMER, saveOnTimer);
				tmrSaveDelay.start();
			}
			
			events.dispatchEvent(new DataEvent(DataEvent.DATA_UPDATE));
		}
		
		private function saveOnTimer(e:TimerEvent):void
		{
			saveFile();
			tmrSaveDelay.removeEventListener(TimerEvent.TIMER, saveOnTimer);
			tmrSaveDelay = null;
		}
		
		private function swapNodes(target:XML, indexa:int, indexb:int):void
		{
			// Sanity checks.
			if (!target) return;
			if (indexa < 0) return;
			if (indexb < 0) return;
			if (indexa == indexb) return;
			
			var anIndex:int;
			
			// Lets say indexa must be < indexb.
			// Just for our own convenience.
			if (indexb < indexa)
			{
				anIndex = indexa;
				indexa = indexb;
				indexb = anIndex;
			}
			
			var aList:XMLList = target.children();
			
			// Last check.
			if (indexb >= aList.length()) return;
			
			var aNode:XML = aList[indexa];
			var bNode:XML = aList[indexb];
			var abNode:XML = aList[indexb - 1];
			
			delete aList[indexb];
			target.insertChildBefore(aNode, bNode)
			
			if (indexb - indexa > 1)
			{
				delete aList[indexa];
				target.insertChildAfter(abNode, aNode);
			}
		}
		
		public function saveFile():void
		{
			if (Capabilities.isDebugger && !DevSettings.dataSaveOn) return;

			// XML output settings
			XML.prettyPrinting = true;
			XML.prettyIndent = 4;

			fstream.open(dataFile, FileMode.WRITE);
			fstream.writeUTFBytes(dataXml.toXMLString());
			fstream.close();

			main.logRed("Data File Saved");
			events.dispatchEvent(new DataEvent(DataEvent.DATA_SAVE));
		}
		
		public function getDataFileRef():File
		{
			return dataFile;
		}
		
		/**
		 * DATA MANAGEMENT INTERFACE
		 * ================================================================================
		 */
		
		public function getAllProducts():Vector.<Product>
		{
			var productsList:Vector.<Product> = new Vector.<Product>();
			
			var p:Product;
			
			for each (var pXml:XML in dataXml.products.product) 
			{
				// [~ Coding task here #CDT ~]: Create entities and return
			}
		}
		 
		public function getAllGroups():Vector.<ItemsGroup>
		{
			var groups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();
			
			var newGrp:ItemsGroup;
			
			// Fields
			for each (var grp:XML in dataXml.groups.itemsGroup)
			{
				newGrp = new ItemsGroup(
					grp.@title,
					grp.@warehouseID
				);
				
				newGrp.dataXml = grp;
				groups.push(newGrp);
			}

			return groups;
		}

		public function getGroupItems(grp:XML):Vector.<SquareItem>
		{
			var items:Vector.<SquareItem> = new Vector.<SquareItem>();
			
			var newItem:SquareItem;
			for each (var itm:XML in grp.item)
			{
				newItem = new SquareItem(int(itm.@productID), int(itm.@count));
				newItem.dataXml = itm;
				items.push(newItem);
			}
			
			return items;
		}
		
		/*
		public function getAllNotes():Vector.<Object>
		{
			var notes:Vector.<Object> = new Vector.<Object>();
			
			for each (var noteRecord:XML in dataXml.notes.itemNote)
			{
				notes.push({imgPath: noteRecord.@img, noteText: noteRecord.@text});
			}
			
			return notes;
		}
		
		public function opNote(op:String, imgPath:String, noteText:String = null):void
		{
			if (op == OP_UPDATE)
			{
				dataXml.notes.itemNote.(@img == imgPath)[0].@text = noteText;
			}
			
			else
			
			if (op == OP_ADD)
			{
				var newNote:XML = <itemNote/>
				newNote.@img = imgPath;
				newNote.@text = noteText;
				dataXml.notes.appendChild(newNote);
			}
			
			else
			
			if (op == OP_REMOVE)
			{
				delete dataXml.notes.itemNote.(@img == imgPath)[0];
			}
			
			dataUpdate(5500);
		}
		*/
		
		public function opGroup(
						grp:ItemsGroup,
						op:String,
						field:String = null,
						value:* = null,
						swapNodeA:XML = null,
						swapNodeB:XML = null):void // [!][~ #TEST THIS ~]
		{
			if (op == OP_UPDATE)
			{
				grp.dataXml.@[field] = value;
			}
			
			else
			
			if (op == OP_ADD)
			{
				var newGroup:XML = <itemsGroup/>
				newGroup.@title = grp.title;
				newGroup.@warehouseID = grp.warehouseID;
				grp.dataXml = newGroup;
				dataXml.groups.appendChild(newGroup);
			}
			
			else
			
			if (op == OP_REMOVE)
			{
				delete dataXml.groups.children()[grp.dataXml.childIndex()];
			}
			
			else
			
			if (op == OP_SWAP_ELEMENTS)
			{
				swapNodes(dataXml.groups, swapNodeA.childIndex(), swapNodeB.childIndex());
			}
			
			dataUpdate();
		}
		
		public function opItem(item:SquareItem, op:String, field:String = null, value:* = null):void
		{
			if (op == OP_UPDATE)
			{
				item.dataXml.@[field] = value;
			}
			
			else
			
			if (op == OP_ADD)
			{
				var newItem:XML = <item/>;
				newItem.@count = item.count;
				newItem.@productID = item.productID;
				
				item.parentItemsGroup.dataXml.appendChild(newItem);
				item.dataXml = newItem;
			}
			
			else
			
			if (op == OP_REMOVE)
			{
				delete item.parentItemsGroup.dataXml.item[item.dataXml.childIndex()];
			}
			
			dataUpdate();
		}
		
		// [!][~ #TEST THIS ~]
		public function opProduct(id:int, op:String, field:String = null, value:* = null):* // [!] Should return field's value on OP_READ
		{
			function queryByID():XML
			{
				var xmlQueryList:XMLList = dataXml.products.product.(@id == id);
				var len:int = xmlQueryList.length();
				
				if (len > 0) 
				{
					if (len > 1) throw new Error("Product should be unique");
					return xmlQueryList[0];
				}
				else
				{
					return null;
				}
			}
			
			var productEntry:XML;
			
			if (op == OP_READ) 
			{
				productEntry = queryByID();
				if (productEntry == null) return null;
				return productEntry.@[field];
			}
			
			else
			
			if (op == OP_UPDATE) 
			{
				productEntry = queryByID();
				productEntry.@[field] = value;
			}
			
			else
			
			if (op == OP_ADD) 
			{
				// return created entry
			}
			
			else
			
			if (op = OP_REMOVE) 
			{
				
			}
			
			dataUpdate();
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get events():EventDispatcher
		{
			return $events;
		}
	}
}