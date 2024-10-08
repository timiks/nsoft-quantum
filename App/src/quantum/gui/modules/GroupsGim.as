package quantum.gui.modules
{
	import fl.controls.UIScrollBar;
	import fl.events.ScrollEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.Settings;
	import quantum.SoundMgr;
	import quantum.data.DataMgr;
	import quantum.dev.DevSettings;
	import quantum.events.PropertyEvent;
	import quantum.events.SettingEvent;
	import quantum.gui.Colors;
	import quantum.gui.elements.ItemsGroup;
	import quantum.gui.elements.GroupItem;
	import quantum.gui.modules.QnManagerGim;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	import quantum.warehouse.Warehouse;
	import quantum.warehouse.WarehouseEntity;
	import timicore.ColorTools;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class GroupsGim extends Sprite
	{
		private const SIDE_MARGIN:int = 7; // GRP_SPACING / 2 (Prev: 14)
		private const CNT_Y_OFFSET:int = 42;
		private const GRP_SPACING:int = 14; // 30
		
		private const groupColorAreaLineThickness:int = 8;
		
		// Fields of app properties
		private var $selectedItem:GroupItem;
		private var $selectedGroup:ItemsGroup;
		private var $events:EventDispatcher;
		private var $empty:Boolean;
		
		private var main:Main;
		private var baseState:QnManagerGim;
		private var pm:ProductsMgr;
		
		private var groups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();
		
		private var cnt:Sprite; // Display container for groups
		private var scb:UIScrollBar; // Scroll bar
		private var cropRect:Rectangle; // Visible area
		private var cntHitBox:Sprite;
		private var groupsColorFillsCanvas:Sprite;
		
		// Scroll
		private const initialScrollSpeed:int = 24;
		private var appliedScrollSpeed:int;
		private var scrollDirection:Boolean; // Either right or left (boolean)
		private var lastMouseWheelDelta:int;
			
		// Selection
		private var groupSelectionRect:Sprite;
		private var groupSelectTimer:Timer;
		private var itemSelectionSticker:ItemSelectionOutlineAnimated;
		
		public function GroupsGim(baseState:QnManagerGim):void
		{
			this.baseState = baseState;
			main = Main.ins;
			pm = baseState.productsMgr;
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			$events = new EventDispatcher();
			
			groups = new Vector.<ItemsGroup>();
			cnt = new Sprite();
			
			cnt.y = CNT_Y_OFFSET;
			focusRect = false;
			
			if (Capabilities.isDebugger && !DevSettings.loadData) return;
			
			// Load groups
			groups = main.dataMgr.getAllGroups();
			
			if (groups.length == 0)
			{
				main.logRed("No groups found");
			}
			
			else
			{
				// Construct groups
				var sizesSum:int = 0;
				
				for each (var itmGrp:ItemsGroup in groups)
				{
					itmGrp.grpCnt = this;
					itmGrp.init();
					
					cnt.addChild(itmGrp.displayObject);
					itmGrp.displayObject.x = SIDE_MARGIN + sizesSum;
					itmGrp.displayObject.y = SIDE_MARGIN * 2;
					sizesSum += itmGrp.realWidth + GRP_SPACING;
				}
				
				sizesSum -= GRP_SPACING;
			}
			
			// Scroll
			cropRect = new Rectangle(0, 0, stage.stageWidth, 548);
			cnt.scrollRect = cropRect;
			
			scb = new UIScrollBar;
			scb.direction = "horizontal";
			scb.setScrollProperties(cropRect.width, 0, calculateMaxScrollPosition(groups.length > 0 ? sizesSum : 0));
			scb.width = cropRect.width;
			scb.y = cnt.y + cropRect.height - scb.height;
			scb.x = 0;
			
			main.logRed("Container width (init): " + cnt.width);
			main.logRed("Max scroll position (init): " + scb.maxScrollPosition);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			scb.addEventListener(ScrollEvent.SCROLL, scroll);
			
			// Set scroll position from settings (with a little delay due to bug)
			var tmr:Timer = new Timer(200, 1);
			tmr.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void 
			{
				var savedScrollPosition:Number = main.settings.getKey(Settings.groupsViewScrollPosition);
				if (savedScrollPosition is Number && savedScrollPosition >= 0 && savedScrollPosition <= scb.maxScrollPosition)
					scb.scrollPosition = savedScrollPosition;
					
				e.currentTarget.removeEventListener(e.type, arguments.callee);
				tmr = null;
			});
			tmr.start();
			
			scb.update();
			
			// Hit box
			cntHitBox = new Sprite();
			cntHitBox.graphics.beginFill(0xF7EBEC, 0);
			cntHitBox.graphics.drawRect(0, 0, cropRect.width, cropRect.height);
			cntHitBox.graphics.endFill();
			cntHitBox.y = CNT_Y_OFFSET;
			cntHitBox.addEventListener(MouseEvent.CLICK, cntHitBoxClick);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			
			// Check empty groups
			if (main.settings.getKey(Settings.deleteEmptyGroupsOnStartup))
			{
				var emptyGroups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();
				for each (var grp:ItemsGroup in groups)
				{
					if (grp.empty) emptyGroups.push(grp);
				}
				
				if (emptyGroups.length > 0)
				{
					for each (var emptyGrp:ItemsGroup in emptyGroups)
					{
						removeGroup(emptyGrp);
						trace("EMPTY GROUP REMOVED");
					}
					emptyGroups = null;
				}
			}
			
			// Item selection sticker
			itemSelectionSticker = new ItemSelectionOutlineAnimated();
			itemSelectionSticker.visible = false;
			itemSelectionSticker.mouseEnabled = false;
			
			// Group selection rect
			groupSelectionRect = new Sprite();
			groupSelectionRect.visible = false;
			groupSelectionRect.addEventListener(MouseEvent.CLICK, cntHitBoxClick);
			
			// Group select timer
			groupSelectTimer = new Timer(2000, 1);
			groupSelectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onSelectTimer);
			
			// Groups color fills canvas
			groupsColorFillsCanvas = new Sprite();
			groupsColorFillsCanvas.cacheAsBitmap = true;
			groupsColorFillsCanvas.addEventListener(MouseEvent.CLICK, cntHitBoxClick);
			redrawGroupsColorFills();
			
			// Layers display order
			/* 1. Groups container hit box */
			addChild(cntHitBox);
			/* 2. Groups container */
			addChild(cnt);
			/* 3. Container → Groups color fills canvas */
			cnt.addChildAt(groupsColorFillsCanvas, 0);
			/* 4. Container → Group selection rectangle */
			cnt.addChildAt(groupSelectionRect, 1);
			/* 5. Container → Groups */
			/* 6. Container → Item selection sticker (foremost — dynamically set) */
			cnt.addChildAt(itemSelectionSticker, cnt.numChildren);
			/* 7. Scroll bar */
			addChild(scb);
			
			// Additional listeners
			main.settings.eventDsp.addEventListener(SettingEvent.VALUE_CHANGED, onSettingChange);
		}
		
		private function onMouseWheel(e:MouseEvent):void
		{
			if (!scb.visible) return;
							
			scrollDirection = e.delta > 0 ? true : false;
			
			appliedScrollSpeed = appliedScrollSpeed == 0 || e.delta != lastMouseWheelDelta ? 
				initialScrollSpeed : (appliedScrollSpeed < initialScrollSpeed * 2 ? appliedScrollSpeed + 10 : appliedScrollSpeed);
				
			stage.addEventListener(Event.ENTER_FRAME, rollScroll);
			lastMouseWheelDelta = e.delta;
		}
		
		private function rollScroll(e:Event):void 
		{
			scb.scrollPosition += scrollDirection ? -appliedScrollSpeed : appliedScrollSpeed;
			appliedScrollSpeed -= 2;
			
			if (appliedScrollSpeed < 1)
			{
				stage.removeEventListener(Event.ENTER_FRAME, rollScroll);
				appliedScrollSpeed = 0;
			}
		}
		
		private function scroll(e:Event):void
		{
			var rct:Rectangle = cropRect; /*cnt.scrollRect*/
			rct.x = scb.scrollPosition;
			cnt.scrollRect = rct;
			main.settings.setKey(Settings.groupsViewScrollPosition, scb.scrollPosition);
		}
		
		private function calculateMaxScrollPosition(groupsSizesSum:Number):Number
		{
			cnt.scrollRect = null;
			
			var bd:BitmapData = new BitmapData(1, 1, false);
			bd.draw(cnt);
			bd.dispose();
			
			var msp:Number = (/*cnt.width*/groupsSizesSum - cropRect.width) + (SIDE_MARGIN * 2);
			
			cnt.scrollRect = cropRect;
			scb.visible = msp > 0 ? true : false;
			
			return msp;
		}
			
		private function keyDown(e:KeyboardEvent):void
		{
			// DELETE
			if (e.keyCode == Keyboard.DELETE)
			{
				
			}
			
			else
				
			// F8
			if (e.keyCode == Keyboard.F8)
			{
				
			}
			
			else
			
			if (e.keyCode == Keyboard.LEFT) 
			{
				moveSelectedGroup("left");
			}
			
			else
			
			if (e.keyCode == Keyboard.RIGHT) 
			{
				moveSelectedGroup("right");
			}
		}
		
		private function cntHitBoxClick(e:MouseEvent):void
		{
			resetSelected();
			
			if (baseState.grpTitleTextInput.tf.visible && !baseState.grpTitleTextInput.focused)
				baseState.grpTitleTextInput.hide();
			
			stage.focus = this;
		}
		
		private function onSelectTimer(e:TimerEvent):void
		{
			resetSelected(true);
			baseState.grpTitleTextInput.hide();
		}
		
		private function resetSelected(onlyGroup:Boolean = false):void
		{
			if (selectedGroup != null)
			{
				selectedGroup.selected = false;
				selectedGroup = null;
				redrawGroupsColorFills();
			}
			
			if (onlyGroup) return;
			
			if (selectedItem != null)
			{
				selectedItem.selected = false;
				selectedItem = null;
			}
		}
		
		private function rearrange():void
		{
			var sizesSum:int = 0;
			for each (var grp:ItemsGroup in groups)
			{
				grp.displayObject.x = SIDE_MARGIN + sizesSum;
				grp.displayObject.y = SIDE_MARGIN * 2;
				sizesSum += grp.realWidth + GRP_SPACING;
			}
			
			sizesSum -= GRP_SPACING;
			
			var prevScrollPos:Number = scb.scrollPosition;
			scb.maxScrollPosition = calculateMaxScrollPosition(sizesSum);
			scb.update();
			scb.scrollPosition = prevScrollPos;
			
			trace("Max scroll position (rearrange): " + scb.maxScrollPosition);
			trace("Container width (rearrange): " + cnt.width);
		}
		
		private function recalculateItemSelectionStickerPosition():void 
		{
			if (selectedItem == null) return;
			
			itemSelectionSticker.x = selectedItem.parentItemsGroup.displayObject.x + selectedItem.x - 15;
			itemSelectionSticker.y = selectedItem.parentItemsGroup.displayObject.y + selectedItem.y - 15;
			cnt.setChildIndex(itemSelectionSticker, cnt.numChildren-1);
		}
		
		private function redrawGroupsColorFills():void 
		{
			groupsColorFillsCanvas.graphics.clear();
			
			if (!main.settings.getKey(Settings.paintColorForGroups)) 
			{
				redrawGroupSelectionRectangle(false);
				return;
			}
			
			const sideMargin:int = GRP_SPACING / 2;
			var color:uint;
			var w:Number, h:Number;
			var xCoord:int;
			var gWH:WarehouseEntity;
			var selectedGroupHasColor:Boolean = false;
			
			for each (var g:ItemsGroup in groups) 
			{
				if (g.isUntitled || g.warehouseID == Warehouse.NONE)
					continue;
				
				gWH = Warehouse.getByID(g.warehouseID);
					
				color = 0;
				color = gWH.uniqueColor;
					
				if (color == 0)
					continue;
					
				xCoord = g.displayObject.x - sideMargin;
				groupsColorFillsCanvas.graphics.moveTo(xCoord, 0);
				
				w = g.realWidth + sideMargin * 2;
				h = cropRect.height;
				
				// Color line
				groupsColorFillsCanvas.graphics.beginFill(color);
				groupsColorFillsCanvas.graphics.drawRect(xCoord, 0, w, groupColorAreaLineThickness);
				groupsColorFillsCanvas.graphics.endFill();
				
				if (g.selected)
				{
					selectedGroupHasColor = true;
					continue;
				}
				
				// Back fill
				groupsColorFillsCanvas.graphics.beginFill(color, 0.2);
				groupsColorFillsCanvas.graphics.drawRect(xCoord, groupColorAreaLineThickness, w, h);
				groupsColorFillsCanvas.graphics.endFill();
			}
			
			redrawGroupSelectionRectangle(selectedGroupHasColor);
		}
		
		private function redrawGroupSelectionRectangle(selectedGroupHasColor:Boolean = false):void 
		{
			if (selectedGroup == null)
				return;
			
			var settingAllows:Boolean = main.settings.getKey(Settings.paintColorForGroups);
			var g:ItemsGroup = selectedGroup;
			var gWhColor:uint = Warehouse.getByID(g.warehouseID).uniqueColor;
			var color:uint = 
				!settingAllows ? Colors.UI_GROUP_SELECTION :
					(g.isUntitled || gWhColor == 0 ? Colors.UI_GROUP_SELECTION : ColorTools.shadeColor(gWhColor, 0.4));
			var alpha:Number = color == Colors.UI_GROUP_SELECTION ? 0.4 : 1;
			
			groupSelectionRect.graphics.clear();
			groupSelectionRect.graphics.beginFill(color, alpha);
			groupSelectionRect.graphics.drawRect(
				0, (selectedGroupHasColor ? groupColorAreaLineThickness : 0), g.realWidth + GRP_SPACING, cropRect.height);
			groupSelectionRect.graphics.endFill();
			
			groupSelectionRect.x = g.displayObject.x - GRP_SPACING / 2;
			groupSelectionRect.visible = true;
		}
		
		private function moveSelectedGroup(direction:String):void 
		{
			if (selectedGroup == null) return;
			if (groups.length <= 1) return;
			
			var idx:int;
			var idxNext:int;
			
			if (direction == "left") 
			{
				idx = groups.indexOf(selectedGroup);
				idxNext = idx-1;
				if (idxNext < 0) return;
				swapGroups(selectedGroup, groups[idxNext]);
			}
			
			else
			
			if (direction == "right") 
			{
				idx = groups.indexOf(selectedGroup);
				idxNext = idx+1;
				if (idxNext > groups.length-1) return;
				swapGroups(selectedGroup, groups[idxNext]);
			}
			
			function swapGroups(grpA:ItemsGroup, grpB:ItemsGroup):void 
			{
				var idxA:int = groups.indexOf(grpA);
				var idxB:int = groups.indexOf(grpB);
				groups[idxA] = grpB;
				groups[idxB] = grpA;
				compositionChanged();
				main.dataMgr.opGroup(null, DataMgr.OP_SWAP_ELEMENTS, null, null, grpA.dataXml, grpB.dataXml);
			}
		}
		
		private function onSettingChange(e:SettingEvent):void 
		{
			if (e.settingName == Settings.paintColorForGroups) 
			{
				redrawGroupsColorFills();
			}
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function selectItem(item:GroupItem):void
		{
			if (selectedItem != null && selectedItem !== item)
				selectedItem.selected = false;
			
			selectedItem = item;
			selectedItem.selected = true;
			
			baseState.tableDataComposer.launchAdrProcessing();
		}
		
		public function selectGroup(grp:ItemsGroup):void 
		{
			// Check existed selection
			if (selectedGroup != null && selectedGroup !== grp)
				selectedGroup.selected = false;
			
			// Set new selection
			selectedGroup = grp;
			selectedGroup.selected = true;
			
			redrawGroupsColorFills();
		}
		
		public function selectGroupWithTimer(grp:ItemsGroup):void
		{
			if (baseState.grpTitleTextInput.focused) return;
			selectGroup(grp);
			baseState.grpTitleTextInput.show(selectedGroup.title);
			if (groupSelectTimer.running) groupSelectTimer.stop();
		}
		
		public function updateUiElementData(elmDataID:String, val:*):void
		{
			const nonsenseMessage:String = "Вы втираете мне какую-то дичь";
			var n:Number;
			
			switch (elmDataID)
			{
				case "selGrpTitle":
				{
					if (selectedGroup != null)
						selectedGroup.title = String(val);
					break;
				}
				
				case "selItemCount":
				{
					if (selectedItem != null)
						selectedItem.count = int(val);
					break;
				}
				
				case "selItemTypeNotes":
				{
					if (selectedItem != null)
					{
						if ((val as String).search(/^\s+$/) != -1)
							val = "";
						
						pm.opProduct(selectedItem.productID, 
							DataMgr.OP_UPDATE, Product.prop_note, String(val));
					}
					break;
				}
				
				case "selItemProductPrice":
				{
					if (selectedItem != null)
					{
						n = main.numFrm.parseNumber(val);
						
						if (isNaN(n))
						{
							baseState.infoPanel.showMessage(nonsenseMessage, Colors.WARN);
						}
						else
						{
							pm.opProduct(selectedItem.productID, 
								DataMgr.OP_UPDATE, Product.prop_price, n);
						}
					}
					
					break;
				}
					
				case "selItemProductWeight":
				{
					if (selectedItem != null)
					{
						n = main.numFrm.parseNumber(val);
						
						if (isNaN(n))
						{
							baseState.infoPanel.showMessage(nonsenseMessage, Colors.WARN);
						}
						else
						{
							pm.opProduct(selectedItem.productID, 
								DataMgr.OP_UPDATE, Product.prop_weight, n);
						}
					}
					
					break;
				}
				
				case "selItemProductSKU":
				{
					if (selectedItem != null)
					{
						var checkSkuID:int = pm.checkProductBySKU(String(val));
						if (checkSkuID != -1 && checkSkuID != selectedItem.productID) 
						{
							baseState.infoPanel.showMessage("Товар с таким SKU уже существует", Colors.WARN);
							pm.opProduct(selectedItem.productID, 
								DataMgr.OP_UPDATE, Product.prop_sku, ""); // Reset SKU
						}
						else
						{
							pm.opProduct(selectedItem.productID, 
								DataMgr.OP_UPDATE, Product.prop_sku, String(val));
						}
					}
					
					break;
				}
			}
		}
		
		public function registerItemsHint(itemsDisOb:InteractiveObject, itemsHintHandler:Function):void
		{
			baseState.hintMgr.registerHintWithHandler(itemsDisOb, itemsHintHandler);
		}
		
		public function addNewGroup():ItemsGroup
		{
			var newGroup:ItemsGroup = new ItemsGroup(ItemsGroup.UNTITLED_GROUP_SIGN, main.settings.getKey(Settings.defaultWarehouse));
			main.dataMgr.opGroup(newGroup, DataMgr.OP_ADD);
			groups.push(newGroup);
			newGroup.grpCnt = this;
			newGroup.brandNew = true;
			newGroup.init();
			cnt.addChild(newGroup.displayObject);
			compositionChanged();
			
			if (scb.maxScrollPosition > 0) scb.scrollPosition = scb.maxScrollPosition;
			
			return newGroup;
		}
		
		public function removeGroup(removingGroup:ItemsGroup):void
		{
			trace("REMOVING GROUP");
			if (selectedGroup == removingGroup) resetSelected();
			main.dataMgr.opGroup(removingGroup, DataMgr.OP_REMOVE);
			cnt.removeChild(removingGroup.displayObject);
			groups.splice(groups.indexOf(removingGroup), 1);
			compositionChanged();
		}
		
		public function itemRemoved():void
		{
			resetSelected();
			compositionChanged();
		}
		
		public function compositionChanged():void
		{
			rearrange();
			recalculateItemSelectionStickerPosition();
			redrawGroupsColorFills();
		}
		
		public function childGroupDataChanged(g:ItemsGroup, event:PropertyEvent):void 
		{
			if (event.observablePropertyID == ItemsGroup.observableProperty_warehouseID || 
				event.observablePropertyID == ItemsGroup.observableProperty_title)
				redrawGroupsColorFills();
		}
		
		public function stopSelTimer():void
		{
			if (groupSelectTimer.running) groupSelectTimer.stop();
		}
		
		public function grpTitleInputFocusOut():void
		{
			onSelectTimer(null);
		}
		
		public function selectedGrpButtonMouseOut():void
		{
			if (baseState.grpTitleTextInput.focused) return;
			
			groupSelectTimer.reset();
			groupSelectTimer.start();
		}
		
		public function processDeletedItemAndMoveToUntitledGroup(deletedItem:GroupItem):void 
		{
			if (getProductFullCount(deletedItem.productID) > 0) 
				return;
			
			var i:int;
			var g:ItemsGroup;
			var untitledGroup:ItemsGroup;
			
			// Search from the end (add to last untitled group in list)
			for (i = groups.length-1; i >= 0; i--) 
			{	
				g = groups[i];
				if (g.title == ItemsGroup.UNTITLED_GROUP_SIGN)
				{
					untitledGroup = g;
					break;
				}
			}
			
			if (untitledGroup == null)
			{
				// Create new
				var newUntitledGroup:ItemsGroup = addNewGroup();
				newUntitledGroup.addItem(deletedItem.productID);
				baseState.infoPanel.showMessage("Товар кончился и был добавлен в новую безымянную группу");
			}
			else
			{
				// Don't add if this product already presented at least in one group in ALL groups space
				if (checkProductExistenceInAllGroups(deletedItem.productID))
				{
					baseState.infoPanel.showMessage("Товар кончился", Colors.WARN);
					return;
				}
				
				// Use found untitled group
				untitledGroup.addItem(deletedItem.productID);
				baseState.infoPanel.showMessage("Товар кончился и был добавлен в последнюю безымянную группу");
			}
		}
		
		public function checkProductExistenceInAllGroups(productID:int):Boolean 
		{
			for each (var g:ItemsGroup in groups)
			{
				if (g.checkItemExistenceByProductID(productID)) 
					return true;
			}
			
			return false;
		}
		
		public function getProductFullCount(productID:int):int
		{
			var fullCount:int = 0;
			
			for each (var g:ItemsGroup in groups) 
			{
				// [!] Exclude untitled groups AND groups with no warehouse
				if (g.isUntitled || g.warehouseID == Warehouse.NONE)
					continue;
				fullCount += g.getProductFullCount(productID);
			}
			
			return fullCount;
		}
		
		public function createInStockProductsFullReport():void 
		{
			if (groups.length == 0)
			{
				main.qnMgrGim.infoPanel.showMessage("Деление на ноль", Colors.WARN);
				return;
			}
			
			var inStockProductsTotal:Dictionary = new Dictionary();
			var groupContainedProductsList:Vector.<int>;
			
			// [!] For active warehouse groups only
			for each (var g:ItemsGroup in groups) 
			{
				if (g.isActiveWarehouseGroup && !g.empty) 
				{
					groupContainedProductsList = g.getContainedProductsList();
					
					if (groupContainedProductsList == null)
						continue;
					
					var pFullCountInGroup:int;
					for each (var pid:int in groupContainedProductsList) 
					{
						pFullCountInGroup = g.getProductFullCount(pid);
						
						if (inStockProductsTotal[pid] == null)
						{
							inStockProductsTotal[pid] = pFullCountInGroup;
						}
						else
						{
							inStockProductsTotal[pid] = inStockProductsTotal[pid] + pFullCountInGroup;
						}
					}
				}
			}
			
			var outputList:Array = [];
			var pSkuVal:String;
			
			for (var pidKey:Object in inStockProductsTotal) 
			{
				pSkuVal = pm.opProduct(int(pidKey), DataMgr.OP_READ, Product.prop_sku) as String;
				
				if (pSkuVal == "" || pSkuVal == null)
					pSkuVal = "[Без SKU · ID товара: " + pidKey.toString() +  "]";
					
				outputList.push({ pid: pidKey, sku: pSkuVal, countTotal: inStockProductsTotal[pidKey]});
			}
			
			if (outputList.length <= 0)
			{
				main.qnMgrGim.infoPanel.showMessage("Ничего не нашлось", Colors.WARN);
				return;
			}
			
			// ================
			// Ok sector
			// ================
			
			// Sort alphabetically
			outputList = outputList.sortOn("sku");
			
			// Write result to file
			var i:int;
			var len:int = outputList.length;
			var line:String;
			var fileStr:String = "";
			var lineEnding:String = "\r\n";
			
			for (i = 0; i < len; i++)
			{
				line = outputList[i].countTotal + "\t" + outputList[i].sku;
				fileStr += (i < len-1) ? line + lineEnding : line;
			}
			
			var exportFile:File = File.applicationStorageDirectory.resolvePath("instock-sum.txt");
			var fst:FileStream = new FileStream();
			
			fst.open(exportFile, FileMode.WRITE);
			fst.writeUTFBytes(fileStr);
			fst.close();
			
			main.qnMgrGim.infoPanel.showMessage("Отчёт готов: " + exportFile.name, Colors.SUCCESS);
			main.soundMgr.play(SoundMgr.sndSuccess);
		}
		
		public function selItemWeightEditHintTextHandler():String
		{
			const defLabel:String = "Вес товара (в КГ)";
			
			if (selectedItem == null)
			{
				return defLabel;
			}
			
			var selItemProduct:Product;
			selItemProduct = pm.getProductByID(selectedItem.productID);
			
			if (selItemProduct.weightStatList.length <= 0 || selItemProduct.weightStatList.length == 1)
				return defLabel;
			
			var weightStatText:String = "";
			var w:Number;
			var useGramForWeight:Boolean = false;
			var count:uint = 0;
			
			weightStatText += "<b>Вес посылки</b>\n";
			
			for each (w in selItemProduct.weightStatList) 
			{
				if (isNaN(w))
					continue;
					
				if (w < 1)
				{
					useGramForWeight = true;
					w *= 1000;
				}
				else 
				{
					useGramForWeight = false;
				}
				
				weightStatText += String(++count) + ". " + 
					(main.numFrm.formatNumber(w) as String) + " " + (useGramForWeight ? "г" : "кг") + "\n";
			}
			
			return weightStatText;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get selectedItem():GroupItem
		{
			return $selectedItem;
		}
		
		public function set selectedItem(value:GroupItem):void
		{
			$selectedItem = value;
			
			baseState.updateUiElement("selItemCount", value == null ? 0 : value.count);
			
			baseState.updateUiElement("selItemTypeNotes", value == null ?
				"" : pm.opProduct(value.productID, DataMgr.OP_READ, Product.prop_note) as String);
				
			baseState.updateUiElement("selItemProductPrice", value == null ?
				"" : pm.opProduct(value.productID, DataMgr.OP_READ, Product.prop_price));
				
			baseState.updateUiElement("selItemProductWeight", value == null ?
				"" : pm.opProduct(value.productID, DataMgr.OP_READ, Product.prop_weight));
				
			baseState.updateUiElement("selItemProductSKU", value == null ? 
				"" : pm.opProduct(value.productID, DataMgr.OP_READ, Product.prop_sku));
				
			baseState.focusAdrTextArea(value == null || value.parentItemsGroup.isUntitled ? false : true);
			
			// Item selection animated sticker
			if (value == null)
			{
				itemSelectionSticker.visible = false;
				itemSelectionSticker.gotoAndStop(1);
			}
			
			else
			{
				/* Calculate coords */
				recalculateItemSelectionStickerPosition();
				itemSelectionSticker.gotoAndPlay(1);
				itemSelectionSticker.visible = true;
			}
		}
		
		public function get selectedGroup():ItemsGroup
		{
			return $selectedGroup;
		}
		
		public function set selectedGroup(value:ItemsGroup):void
		{
			$selectedGroup = value;
			
			if (value == null)
			{
				groupSelectionRect.graphics.clear();
				groupSelectionRect.visible = false;
				return;
			}
			
			redrawGroupSelectionRectangle();
		}
		
		public function get image():Bitmap
		{
			var imgSprite:Sprite = new Sprite();
			
			var grpImage:Bitmap;
			var sizesSum:int = 0;
			for each (var g:ItemsGroup in groups)
			{
				grpImage = new Bitmap(new BitmapData(g.realWidth, g.displayObject.height));
				grpImage.bitmapData.draw(g.displayObject);
				grpImage.x = SIDE_MARGIN + sizesSum;
				grpImage.y = SIDE_MARGIN;
				imgSprite.addChild(grpImage);
				sizesSum += g.realWidth + GRP_SPACING;
			}
			
			var bd:BitmapData = new BitmapData(imgSprite.width + SIDE_MARGIN * 2, imgSprite.height + SIDE_MARGIN * 2, false, 0xFFFFFF);
			bd.draw(imgSprite);
			
			return new Bitmap(bd);
		}
		
		public function get events():EventDispatcher 
		{
			return $events;
		}
		
		public function get empty():Boolean 
		{
			return groups.length == 0 ? true : false;
		}
	}
}