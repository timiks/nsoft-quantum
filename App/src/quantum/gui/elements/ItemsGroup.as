package quantum.gui.elements
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.CapsStyle;
	import flash.display.GraphicsSolidFill;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.MovieClip;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import quantum.Main;
	import quantum.Settings;
	import quantum.SoundMgr;
	import quantum.data.DataMgr;
	import quantum.events.PropertyEvent;
	import quantum.events.SettingEvent;
	import quantum.gui.Colors;
	import quantum.gui.buttons.BtnGroupControl;
	import quantum.gui.elements.GroupItem;
	import quantum.gui.modules.GroupsGim;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	import quantum.warehouse.Warehouse;
	import quantum.warehouse.WarehouseEntity;
	
	/**
	 * UI-element: Group with items
	 * 2016.Q4
	 * @author Tim Yusupov
	 */
	public class ItemsGroup
	{
		public static const UNTITLED_GROUP_SIGN:String = ""; // And dev-feature marker
		
		// Observable properties constants
		public static const observableProperty_title:String = "title";
		public static const observableProperty_warehouseID:String = "warehouseID";
		public static const observableProperty_isTransparent:String = "isTransparent";
		public static const observableProperty_selected:String = "selected";
		
		// Persistent properties (attributes) of corresp. XML-entities in DB
		public static const xmlEntityAttr_title:String = "title"; // = 'title'
		public static const xmlEntityAttr_warehouseID:String = "warehouseID"; // = 'warehouseID'
		public static const xmlEntityAttr_transpFlag:String = "transpFlag"; // = 'isTransparent'
		
		private const MAX_ITEMS_NUMBER_VERTICALLY:int = 10;
		private const ITEMS_SPACING:int = 6; // In pixels
		private const ITEMS_PLACING_Y_OFFSET:int = 45;
		
		// Fields of app properties
		private var $events:EventDispatcher;
		private var $displayObject:Sprite;
		private var $id:int;
		private var $selected:Boolean;
		private var $dataXml:XML;
		private var $grpCnt:GroupsGim;
		private var $brandNew:Boolean;
		private var $empty:Boolean;
		private var $isUntitled:Boolean;
		
		// Fields of data properties
		private var $title:String;
		private var $warehouseID:String;
		private var $isTransparent:Boolean;
		
		private var main:Main;
		private var pm:ProductsMgr;
		
		private var totalItems:int;
		private var totalColumns:int;
		private var items:Vector.<GroupItem>;
		private var nextPlace:Point;
		private var imgFile:File;
			
		private var btnNewItem:BtnGroupControl;
		private var ctxMenu:NativeMenu;
		
		private var menuItmDeleteThisGroup:NativeMenuItem;
		private var menuItmExport:NativeMenuItem;
		private var menuItmExportInStockSumReport:NativeMenuItem;
		private var menuItmWarehouseSwitchRef:NativeMenuItem;
		private var menuItmTransparentFlagControl:NativeMenuItem;
		
		public function ItemsGroup(title:String = "", warehouseID:String = "", isTransparentFlag:Boolean = false):void
		{
			this.title = title;
			this.warehouseID = warehouseID;
			this.isTransparent = isTransparentFlag;
			
			main = Main.ins;
			pm = main.qnMgrGim.productsMgr;
		}
		
		public function init():void
		{
			$events = new EventDispatcher();
			
			displayObject = new Sprite();
			displayObject.tabEnabled = false;
			displayObject.tabChildren = false
			
			btnNewItem = new BtnGroupControl();
			
			displayObject.addChild(btnNewItem);
			
			// ================================================================================
			
			items = new Vector.<GroupItem>();
			nextPlace = new Point();
			imgFile = new File();
			constructGrid();
			
			/**
			 * UI functionality
			 * ================================================================================
			 */
			
			// Меню группы
			menuItmDeleteThisGroup = new NativeMenuItem("Удалить группу");
			menuItmDeleteThisGroup.addEventListener(Event.SELECT, menuItmDeleteThisGroupClick);
			
			menuItmTransparentFlagControl = new NativeMenuItem("Сделать товары в группе прозрачными");
			menuItmTransparentFlagControl.checked = isTransparent; // Initial setup
			menuItmTransparentFlagControl.addEventListener(Event.SELECT, menuItmTransparentFlagControlClick);
			
			menuItmExport = new NativeMenuItem("Экспорт содержимого группы в файл");
			menuItmExport.addEventListener(Event.SELECT, menuItmExportClick);
			
			menuItmExportInStockSumReport = new NativeMenuItem("Оформить сводный отчёт о наличии товаров в складcких группах");
			menuItmExportInStockSumReport.addEventListener(Event.SELECT, menuItmExportInStockSumReportClick);
			
			// ================================================================================
			
			ctxMenu = new NativeMenu();
			ctxMenu.addItem(menuItmDeleteThisGroup);
			ctxMenu.addItem(menuItmTransparentFlagControl);
			ctxMenu.addItem(new NativeMenuItem("[separator]", true));
			ctxMenu.addItem(menuItmExport);
			ctxMenu.addItem(menuItmExportInStockSumReport);
			ctxMenu.addItem(new NativeMenuItem("[separator]", true));
			
			// Элементы подменю выбора склада
			for each (var whEnt:WarehouseEntity in Warehouse.entitiesList)
			{
				if (whEnt.uiDisabled)
					continue;
				
				menuItmWarehouseSwitchRef = new NativeMenuItem(
					whEnt.ID == Warehouse.NONE ? "Без склада" : "Переключить склад на «" + whEnt.russianTitle + "»");
				menuItmWarehouseSwitchRef.data = whEnt.ID;
				menuItmWarehouseSwitchRef.addEventListener(Event.SELECT, menuItmWarehouseSwitchClick);
				
				if (whEnt.ID == warehouseID)
				{
					menuItmWarehouseSwitchRef.enabled = false;
				}
				
				ctxMenu.addItem(menuItmWarehouseSwitchRef);
			}
			
			btnNewItem.contextMenu = ctxMenu;
			
			// Hint
			grpCnt.registerItemsHint(btnNewItem, hintTextHandler);
			
			// Listeners
			btnNewItem.addEventListener(MouseEvent.CLICK, newItemBtnClick);
			btnNewItem.addEventListener(MouseEvent.MOUSE_OVER, newItemBtnOver);
			btnNewItem.addEventListener(MouseEvent.MOUSE_OUT, newItemBtnOut);
			imgFile.addEventListener(FileListEvent.SELECT_MULTIPLE, multipleFilesSelect);
			
			if (title == UNTITLED_GROUP_SIGN)
			{
				checkTitleAndUpdateStyle();
				main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onDimUntitledGroupSettingChange);
			}
		}
		
		private function menuItmDeleteThisGroupClick(e:Event):void 
		{
			grpCnt.removeGroup(this);
		}
		
		private function menuItmTransparentFlagControlClick(e:Event):void 
		{
			isTransparent = !isTransparent;
			menuItmTransparentFlagControl.checked = isTransparent;
		}
		
		private function menuItmWarehouseSwitchClick(e:Event):void
		{
			ctxMenu.items.forEach(function(elm:NativeMenuItem, idx:int, arr:Array):void
			{
				if (elm.data != (e.target as NativeMenuItem).data && !elm.enabled)
					elm.enabled = true;
				
				if (elm.data == (e.target as NativeMenuItem).data)
					elm.enabled = false;
			});
			
			warehouseID = (e.target as NativeMenuItem).data as String;
		}
		
		private function menuItmExportClick(e:Event):void
		{
			exportGroup();
		}
		
		private function menuItmExportInStockSumReportClick(e:Event):void 
		{
			grpCnt.createInStockProductsFullReport();
		}
		
		private function exportGroup():void
		{
			if (empty)
			{
				main.qnMgrGim.infoPanel.showMessage("Группа пустая", Colors.WARN);
				return;
			}
			
			if (isUntitled)
			{
				main.qnMgrGim.infoPanel.showMessage("Для безымянной группы данная функция не доступна", Colors.WARN);
				return;
			}
			
			var productsIdsList:Vector.<int> = getContainedProductsList();
			var idBadge:String;
			var idBadgeValue:String;
			var PID:int;
			
			switch (warehouseID) 
			{
				case Warehouse.BEIJING:
				case Warehouse.CANTON:
					idBadge = Product.prop_imgFile;
					break;
					
				default:
				case Warehouse.SHENZHEN_SEO:
				case Warehouse.SHENZHEN_CFF:
					idBadge = Product.prop_sku;
					
					for each (PID in productsIdsList) 
					{
						if (pm.opProduct(PID, DataMgr.OP_READ, idBadge) == "")
						{
							main.qnMgrGim.infoPanel.showMessage("Не у всех товаров в этой группе указан SKU", Colors.WARN);
							return;
						}
					}
					break;
			}
			
			var i:int;
			var len:int = productsIdsList.length;
			var line:String;
			var fileStr:String = "";
			var lineEnding:String = "\r\n";
			
			for (i = 0; i < len; i++)
			{
				PID = productsIdsList[i] as int;
				idBadgeValue = pm.opProduct(PID, DataMgr.OP_READ, idBadge) as String;
				
				// "1" {tab} {ProductSKU} {tab} {ProductFullCountInThisGroup)
				line = "1" + "\t" + idBadgeValue + "\t" + String(getProductFullCount(PID));
				
				fileStr += (i < len-1) ? line + lineEnding : line;
			}
			
			var exportFile:File = File.applicationStorageDirectory.resolvePath("quantity.txt");
			var fst:FileStream = new FileStream();
			
			fst.open(exportFile, FileMode.WRITE);
			fst.writeUTFBytes(fileStr);
			fst.close();
			
			main.qnMgrGim.infoPanel.showMessage("Содержимое группы экспортировано в файл " + exportFile.name, Colors.SUCCESS);
			main.soundMgr.play(SoundMgr.sndSuccess);
			
			// Open file with exported content
			/*
			try 
			{
				var defaultTextAppInOS:File = new File(NativeApplication.nativeApplication.getDefaultApplication("txt"));
			}
			catch (err:Error)
			{
				return;
			}
			
			if (defaultTextAppInOS.nativePath == "" || defaultTextAppInOS.nativePath == null)
				return;

			var args:Vector.<String> = new Vector.<String>();
			args.push(exportFile.nativePath);

			var psi:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			psi.executable = defaultTextAppInOS;
			psi.arguments = args;

			var nativeProcess:NativeProcess = new NativeProcess();
			
			try 
			{
				nativeProcess.start(psi);
			}
			catch (err:Error)
			{
				// ...
			}
			*/
		}
		
		private function multipleFilesSelect(e:FileListEvent):void
		{
			var productIDforNewItem:int;
			for each (var file:File in e.files)
			{
				productIDforNewItem = pm.checkProductByImgPath(file.nativePath);
				addItem(productIDforNewItem);
			}
		}
		
		private function newItemBtnClick(e:MouseEvent):void
		{
			imgFile.browseForOpenMultiple(
				"Выберите добавляемые товары через их изображения",
				[new FileFilter("Изображение", "*.jpg;*.png;*.gif;*.jpeg")]
			);
		}
		
		private function newItemBtnOver(e:MouseEvent):void
		{
			grpCnt.selectGroupWithTimer(this);
		}
		
		private function newItemBtnOut(e:MouseEvent):void
		{
			//grpCnt.selectedGrpButtonMouseOut();
		}
		
		private function constructGrid():void
		{
			// Load items for this group
			items = main.dataMgr.getGroupItems(dataXml);
			
			if (items.length == 0)
			{
				main.logRed("No items found for group " + title);
				return;
			}
			
			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);
			
			var i:int;
			var j:int;
			var item:GroupItem;
			var tmpTotalItems:int = items.length;
			var orderNum:int = 1;
			var idx:int = 0;
			
			for (i = 0; i < totalColumns; i++)
			{
				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++)
				{
					item = items[idx++];
					item.parentItemsGroup = this;
					
					if (pm.getProductByID(item.productID) == null) 
					{
						throw new Error("Group contains item with nonexistent product associated");
					}
					
					displayObject.addChild(item);
					item.init();
					
					nextPlace = calculatePlace(i, j, item.frame.width, item.frame.height);
					item.x = nextPlace.x;
					item.y = nextPlace.y;
					
					tmpTotalItems--;
					
					if (tmpTotalItems == 0)
						break;
				}
			}
		}
		
		private function calculatePlace(xCol:int, yRow:int, w:Number, h:Number):Point
		{
			var p:Point = new Point();
			p.x = xCol * (w + ITEMS_SPACING);
			p.y = ITEMS_PLACING_Y_OFFSET + (yRow * (h + ITEMS_SPACING));
			return p;
		}
		
		private function calculateNextPlace():void
		{
			var i:int;
			var j:int;
			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);
			var tmpTotalItems:int = items.length;
			
			for (i = 0; i < totalColumns; i++)
			{
				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++)
				{
					tmpTotalItems--;
					
					if (tmpTotalItems == 0)
					{
						var lastAddedItem:GroupItem = items[items.length-1];
						nextPlace = calculatePlace(i, j, lastAddedItem.frame.width, lastAddedItem.frame.height);
						break;
					}
				}
			}
		}
		
		private function rearrangeItems():void
		{
			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);
			
			var item:GroupItem;
			var i:int;
			var j:int;
			var tmpTotalItems:int = items.length;
			var currentItemIdx:int = 0;
			var orderNum:int = 1;
			
			for (i = 0; i < totalColumns; i++)
			{
				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++)
				{
					item = items[currentItemIdx++];
					
					nextPlace = calculatePlace(i, j, item.frame.width, item.frame.height);
					item.x = nextPlace.x;
					item.y = nextPlace.y;
					tmpTotalItems--;
					
					if (tmpTotalItems == 0) break;
				}
			}
		}
		
		private function checkTitleAndUpdateStyle():void
		{
			if (displayObject == null) return;
			
			if (!main.settings.getKey(Settings.dimUntitledGroupButton) && btnNewItem.alpha != 1)
			{
				btnNewItem.alpha = 1;
				return;
			}
			
			if (!main.settings.getKey(Settings.dimUntitledGroupButton)) return;
			
			if (title == UNTITLED_GROUP_SIGN) 
			{
				btnNewItem.alpha = 0.6;
			}
			
			else
			{
				btnNewItem.alpha = 1;
			}
		}
		
		private function onDimUntitledGroupSettingChange(e:SettingEvent):void
		{
			if (e.settingName == Settings.dimUntitledGroupButton && title == UNTITLED_GROUP_SIGN)
				checkTitleAndUpdateStyle();
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function addItem(productID:int, countValue:int = 0):GroupItem
		{
			var newItem:GroupItem = new GroupItem(
				productID,
				countValue
			);
			
			items.push(newItem);
			newItem.parentItemsGroup = this;
			displayObject.addChild(newItem);
			newItem.init();
			calculateNextPlace();
			newItem.x = nextPlace.x;
			newItem.y = nextPlace.y;
			grpCnt.compositionChanged();
			if (brandNew) brandNew = false;
			main.dataMgr.opItem(newItem, DataMgr.OP_ADD);
			
			return newItem;
		}
		
		public function removeItem(removingItem:GroupItem):void
		{
			items.splice(items.indexOf(removingItem), 1);
			main.dataMgr.opItem(removingItem, DataMgr.OP_REMOVE);
			
			if (!displayObject.contains(removingItem))
				return;
				
			displayObject.removeChild(removingItem);
			rearrangeItems();
			grpCnt.itemRemoved(); // Tell GroupsContainer that item has been removed
			
			if (items.length == 0 && !brandNew)
			{
				grpCnt.removeGroup(this);
			}
			
			if (main.settings.getKey(Settings.moveDeletedItemsToUntitledGroup))
			{
				grpCnt.processDeletedItemAndMoveToUntitledGroup(removingItem);
			}
		}
		
		public function hintTextHandler():String
		{
			if (warehouseID == null || warehouseID == "")
			{
				return null;
			}
			
			return (title == UNTITLED_GROUP_SIGN ? 
						main.qnMgrGim.colorText(Colors.TXLB_LIGHT_GREY, "[Безымянная]") : title) + "\n" + 
					(warehouseID == Warehouse.NONE ?
						main.qnMgrGim.colorText(Colors.TXLB_LIGHT_GREY, Warehouse.getByID(warehouseID).russianTitle) :
						"<b>Склад:</b> " + Warehouse.getByID(warehouseID).russianTitle);
		}
		
		public function checkItemExistenceByProductID(itemProductID:int):Boolean
		{
			for each (var i:GroupItem in items)
			{
				if (i.productID == itemProductID) return true;
			}
			
			return false;
		}
		
		public function getProductFullCount(productID:int):int 
		{
			if (empty)
				return 0;
				
			var fullCount:int = 0;
			
			for each (var i:GroupItem in items) 
			{
				if (i.productID == productID)
					fullCount += i.count;
			}
			
			return fullCount;
		}
		
		public function getContainedProductsList():Vector.<int> 
		{
			if (empty)
				return null;
				
			var tmp:Object = {};
			var idList:Vector.<int> = new Vector.<int>();
			
			for each (var i:GroupItem in items) 
			{
				if (!tmp[i.productID])
					idList.push(i.productID);
				
				tmp[i.productID] = true;
			}
			
			return idList;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		/**
		 * Экранный объект класса
		 */
		public function get displayObject():Sprite
		{
			return $displayObject;
		}
		
		public function set displayObject(value:Sprite):void
		{
			$displayObject = value as Sprite;
		}
		
		/**
		 * ID группы
		 */
		public function get id():int
		{
			return $id;
		}
		
		public function set id(value:int):void
		{
			$id = value;
		}
		
		/**
		 * Название группы
		 */
		public function get title():String
		{
			return $title;
		}
		
		public function set title(value:String):void
		{
			$title = value;
			
			var event:PropertyEvent = new PropertyEvent(PropertyEvent.CHANGED, observableProperty_title);
			if ($events != null) $events.dispatchEvent(event);
			if (grpCnt != null) grpCnt.childGroupDataChanged(this, event); // Special
			
			if (displayObject != null)
			{
				if (title == UNTITLED_GROUP_SIGN)
				{
					main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onDimUntitledGroupSettingChange);
				}
				
				else
				{
					main.settings.eventDsp.removeEventListener(SettingEvent.VALUE_CHANGED, onDimUntitledGroupSettingChange);
				}
			}
			
			checkTitleAndUpdateStyle();
			
			if (main != null) main.dataMgr.opGroup(this, DataMgr.OP_UPDATE, xmlEntityAttr_title, value);
		}
		
		public function get warehouseID():String
		{
			return $warehouseID;
		}
		
		public function set warehouseID(value:String):void
		{
			$warehouseID = value;
			
			var event:PropertyEvent = new PropertyEvent(PropertyEvent.CHANGED, observableProperty_warehouseID);
			if ($events != null) $events.dispatchEvent(event);
			if (grpCnt != null) grpCnt.childGroupDataChanged(this, event); // Special
			
			if (main != null) main.dataMgr.opGroup(this, DataMgr.OP_UPDATE, xmlEntityAttr_warehouseID, value);
		}
		
		public function get isTransparent():Boolean 
		{
			return $isTransparent;
		}
		
		public function set isTransparent(value:Boolean):void 
		{
			$isTransparent = value;
			
			var event:PropertyEvent = new PropertyEvent(PropertyEvent.CHANGED, observableProperty_isTransparent);
			if ($events != null) $events.dispatchEvent(event);
			if (grpCnt != null) grpCnt.childGroupDataChanged(this, event); // Special
			
			// Update persistent DB
			if (main != null) main.dataMgr.opGroup(this, DataMgr.OP_UPDATE, xmlEntityAttr_transpFlag, value);
		}
		
		/**
		 * Выбран ли объект
		 */
		public function get selected():Boolean
		{
			return $selected;
		}
		
		public function set selected(value:Boolean):void
		{
			$selected = value;
			
			if ($events != null) $events.dispatchEvent(new PropertyEvent(PropertyEvent.CHANGED, observableProperty_selected));
			
			if (value == true)
			{
				//(displayObject.getChildByName("btnSelGrp") as MovieClip).gotoAndStop(3);
			}
			else
			{
				//(displayObject.getChildByName("btnSelGrp") as MovieClip).gotoAndStop(1);
			}
		}
		
		public function get realWidth():Number
		{
			return items.length > 0 ?
				((items[0] as GroupItem).frame.width + ITEMS_SPACING) * totalColumns - ITEMS_SPACING :
				displayObject.width;
		}
		
		public function get dataXml():XML
		{
			return $dataXml;
		}
		
		public function set dataXml(value:XML):void
		{
			$dataXml = value;
		}
		
		public function get grpCnt():GroupsGim
		{
			return $grpCnt;
		}
		
		public function set grpCnt(value:GroupsGim):void
		{
			$grpCnt = value;
		}
		
		public function get brandNew():Boolean
		{
			return $brandNew;
		}
		
		public function set brandNew(value:Boolean):void
		{
			$brandNew = value;
		}
		
		public function get empty():Boolean
		{
			return items.length == 0 ? true : false;
		}
		
		public function get isUntitled():Boolean 
		{
			return title == UNTITLED_GROUP_SIGN;
		}
		
		public function get isActiveWarehouseGroup():Boolean
		{
			return warehouseID != Warehouse.NONE && !isUntitled;
		}
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
	}
}