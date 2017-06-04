package quantum.gui {

	import flash.display.MovieClip;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.utils.Timer;
	import quantum.Settings;
	import quantum.data.DataMgr;
	import quantum.Main;
	import quantum.SoundMgr;
	import quantum.Warehouse;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class ItemsGroup extends Sprite {

		private const MAX_ITEMS_NUMBER_VERTICALLY:int = 10; // Ex: 6 7
		private const ITEMS_SPACING:int = 6; // In pixels
		private const ITEMS_PLACING_Y_OFFSET:int = 45;

		// Fields of app properties
		private var $displayObject:ItemsGroupMC;
		private var $id:int;
		private var $selected:Boolean;
		private var $dataXml:XML;
		private var $grpCnt:GroupsContainer;
		private var $brandNew:Boolean;
		private var $empty:Boolean;

		// Fields of data properties
		private var $title:String;
		private var $warehouseID:String;

		private var main:Main;

		private var totalItems:int;
		private var totalColumns:int;
		private var items:Vector.<SquareItem>;
		private var nextPlace:Point;
		private var imgFile:File;
		private var multipleAddingMode:Boolean;

		private var btnSelGrp:MovieClip;
		private var btnNewItem:SimpleButton;
		private var ctxMenu:NativeMenu;

		private var tmpImgs:Array;
		private var menuItmExport:NativeMenuItem;
		private var menuItmWarehouseSwitch:NativeMenuItem;

		public function ItemsGroup(title:String = "", warehouseID:String = ""):void {

			this.title = title;
			this.warehouseID = warehouseID;

			main = Main.ins;

		}

		public function init():void {

			displayObject = new ItemsGroupMC();
			displayObject.tabEnabled = false;
			displayObject.tabChildren = false;

			items = new Vector.<SquareItem>();
			nextPlace = new Point();
			imgFile = new File();
			constructGrid();

			/**
			 * UI functionality
			 * ================================================================================
			 */

			// Кнопка добавления нового объекта в группу
			btnNewItem = displayObject.getChildByName("btnNewItem") as SimpleButton;

			// Меню группы
			menuItmExport = new NativeMenuItem("Экспорт содержимого группы в файл");
			menuItmExport.addEventListener(Event.SELECT, menuItmExportClick);

			menuItmWarehouseSwitch = new NativeMenuItem(getMenuItmWarehouseSwitchLabel());
			menuItmWarehouseSwitch.addEventListener(Event.SELECT, menuItmWarehouseSwitchClick);

			ctxMenu = new NativeMenu();
			ctxMenu.addItem(menuItmExport);
			ctxMenu.addItem(menuItmWarehouseSwitch);
			btnNewItem.contextMenu = ctxMenu;

			// Hint
			grpCnt.registerItemsHint(btnNewItem, hintTextHandler);

			// Listeners
			btnNewItem.addEventListener(MouseEvent.CLICK, newItemBtnClick);
			btnNewItem.addEventListener(MouseEvent.MOUSE_OVER, newItemBtnOver);
			btnNewItem.addEventListener(MouseEvent.MOUSE_OUT, newItemBtnOut);
			imgFile.addEventListener(FileListEvent.SELECT_MULTIPLE, multipleFilesSelect);
			grpCnt.events.addEventListener(GroupsContainer.EVENT_ITEMS_IMG_LOADING_COMPLETE, grpCntImgLoadingComplete);

		}

		private function getMenuItmWarehouseSwitchLabel():String {
			return "Переключить склад [Текущий: " + Warehouse.getRussianTitle(warehouseID) + "]";
		}

		private function menuItmWarehouseSwitchClick(e:Event):void {

			if (warehouseID == Warehouse.BEIJING) {

				warehouseID = Warehouse.CANTON;

			} else {

				warehouseID = Warehouse.BEIJING;

			}

			menuItmWarehouseSwitch.label = getMenuItmWarehouseSwitchLabel();
		}

		private function menuItmExportClick(e:Event):void {
			exportGroup();
		}

		private function exportGroup():void {

			var exportFile:File;
			var fst:FileStream;
			var fileStr:String = "";
			var lineEnding:String = "\r\n";

			exportFile = File.applicationStorageDirectory.resolvePath("quantity.txt");
			fst = new FileStream();

			var i:int;
			var len:int = items.length;
			var line:String;
			var itm:SquareItem;
			for (i = 0; i < len; i++) {

				itm = items[i] as SquareItem;
				line = itm.imagePath + "\t" + String(itm.count);
				fileStr += (i < len-1) ? line + lineEnding : line;

			}

			fst.open(exportFile, FileMode.WRITE);
			fst.writeUTFBytes(fileStr);
			fst.close();

			// Sound
			main.soundMgr.play(SoundMgr.sndPrcSuccess);

			trace("Group contents has been exported to file: " + exportFile.name);

		}

		private function multipleFilesSelect(e:FileListEvent):void {

			multipleAddingMode = true;
			
			for each (var file:File in e.files) {
				addItem(file.nativePath);
			}
			
			grpCnt.startItemsImgLoadingTimer();
			
		}
		
		private function grpCntImgLoadingComplete(e:Event):void 
		{
			if (multipleAddingMode) multipleAddingMode = false;
		}

		private function newItemBtnClick(e:MouseEvent):void {

			imgFile.browseForOpenMultiple(
				"Выберите картинку (или несколько)",
				[new FileFilter("Изображение", "*.jpg;*.png;*.gif;*.jpeg")]
			);

		}

		private function newItemBtnOver(e:MouseEvent):void {
			grpCnt.selectGroupWithTimer(this);
		}

		private function newItemBtnOut(e:MouseEvent):void {
			//grpCnt.selectedGrpButtonMouseOut();
		}

		private function constructGrid():void {

			// Load items for this group
			items = main.dataMgr.getGroupItems(dataXml);

			if (items.length == 0) {

				main.logRed("No items found for group " + title);
				return;

			}

			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);

			var i:int;
			var j:int;
			var item:SquareItem;
			var tmpTotalItems:int = items.length;
			var orderNum:int = 1;
			var idx:int = 0;

			for (i = 0; i < totalColumns; i++) {

				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++) {

					item = items[idx++];
					item.parentItemsGroup = this;
					displayObject.addChild(item);
					item.init();

					nextPlace = calculatePlace(i, j, item.frame.width, item.frame.height);
					item.x = nextPlace.x;
					item.y = nextPlace.y;
					item.position = orderNum++;

					tmpTotalItems--;

					if (tmpTotalItems == 0) break;

				}

			}

		}

		private function calculatePlace(xCol:int, yRow:int, w:Number, h:Number):Point {

			var p:Point = new Point();
			p.x = xCol * (w + ITEMS_SPACING);
			p.y = ITEMS_PLACING_Y_OFFSET + (yRow * (h + ITEMS_SPACING));
			return p;

		}

		private function calculateNextPlace():void {

			var i:int;
			var j:int;
			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);
			var tmpTotalItems:int = items.length;

			for (i = 0; i < totalColumns; i++) {

				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++) {

					tmpTotalItems--;

					if (tmpTotalItems == 0) {
						var lastAddedItem:SquareItem = items[items.length-1];
						nextPlace = calculatePlace(i, j, lastAddedItem.frame.width, lastAddedItem.frame.height);
						break;
					}

				}

			}

		}

		private function rearrangeItems():void {

			totalColumns = Math.ceil(items.length / MAX_ITEMS_NUMBER_VERTICALLY);
			var item:SquareItem;

			var i:int;
			var j:int;
			var tmpTotalItems:int = items.length;
			var currentItemIdx:int = 0;
			var orderNum:int = 1;

			for (i = 0; i < totalColumns; i++) {

				for (j = 0; j < MAX_ITEMS_NUMBER_VERTICALLY; j++) {

					item = items[currentItemIdx++];

					nextPlace = calculatePlace(i, j, item.frame.width, item.frame.height);
					item.x = nextPlace.x;
					item.y = nextPlace.y;
					item.position = orderNum++;
					tmpTotalItems--;

					if (tmpTotalItems == 0) break;

				}

			}

		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function addItem(imgPath:String, countValue:int = 0):SquareItem {

			var newItem:SquareItem = new SquareItem(
				imgPath,
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
			
			if (!multipleAddingMode) grpCnt.startItemsImgLoadingTimer();

			return newItem;

		}

		public function removeItem(removingItem:SquareItem):void {

			main.dataMgr.opItem(removingItem, DataMgr.OP_REMOVE);
			displayObject.removeChild(removingItem);
			items.splice(items.indexOf(removingItem), 1);
			rearrangeItems();
			grpCnt.itemRemoved(); // Tell GroupsContainer that item has been removed

			if (items.length == 0 && !brandNew) {
				grpCnt.removeGroup(this);
			}

			if (main.settings.getKey(Settings.moveDeletedItemsToUntitledGroup)) 
			{
				grpCnt.processDeletedItemAndMoveToUntitledGroup(removingItem);
			}
			
		}

		public function hintTextHandler():String {

			if (warehouseID == null || warehouseID == "") {
				return null;
			}

			return (title == "" ? "[Безымянная]" : title) + "\n" + "Склад: " + Warehouse.getRussianTitle(warehouseID);

		}
		
		public function checkItemExistenceByImgPath(itemsImgPath:String):Boolean
		{
			for each (var i:SquareItem in items) 
			{
				if (i.imagePath == itemsImgPath) return true;
			}
			
			return false;
		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		/**
		 * Экранный объект класса
		 */
		public function get displayObject():Sprite {
			return $displayObject;
		}

		public function set displayObject(value:Sprite):void {
			$displayObject = value as ItemsGroupMC;
		}

		/**
		 * ID группы
		 */
		public function get id():int {
			return $id;
		}

		public function set id(value:int):void {
			$id = value;
		}

		/**
		 * Название группы
		 */
		public function get title():String {
			return $title;
		}

		public function set title(value:String):void {
			$title = value;
			if (main != null) main.dataMgr.opGroup(this, DataMgr.OP_UPDATE, "title", value);
		}

		public function get warehouseID():String {
			return $warehouseID;
		}

		public function set warehouseID(value:String):void {
			$warehouseID = value;
			if (main != null) main.dataMgr.opGroup(this, DataMgr.OP_UPDATE, "warehouseID", value);
		}

		/**
		 * Выбран ли объект
		 */
		public function get selected():Boolean {
			return $selected;
		}

		public function set selected(value:Boolean):void {
			$selected = value;

			if (value == true) {
				//(displayObject.getChildByName("btnSelGrp") as MovieClip).gotoAndStop(3);
			} else {
				//(displayObject.getChildByName("btnSelGrp") as MovieClip).gotoAndStop(1);
			}
		}

		public function get realWidth():Number {
			return items.length > 0 ?
				((items[0] as SquareItem).frame.width + ITEMS_SPACING) * totalColumns - ITEMS_SPACING :
				displayObject.width;
		}

		public function get dataXml():XML {
			return $dataXml;
		}

		public function set dataXml(value:XML):void {
			$dataXml = value;
		}

		public function get grpCnt():GroupsContainer {
			return $grpCnt;
		}

		public function set grpCnt(value:GroupsContainer):void {
			$grpCnt = value;
		}

		public function get brandNew():Boolean {
			return $brandNew;
		}

		public function set brandNew(value:Boolean):void {
			$brandNew = value;
		}

		public function get empty():Boolean {
			return items.length == 0 ? true : false;
		}

	}

}