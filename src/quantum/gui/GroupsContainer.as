package quantum.gui
{
	import fl.controls.UIScrollBar;
	import fl.events.ScrollEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import quantum.data.DataMgr;
	import quantum.dev.DevSettings;
	import quantum.Main;
	import quantum.Settings;
	import quantum.states.StQuantumManager;
	import quantum.Warehouse;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class GroupsContainer extends Sprite
	{
		public static const EVENT_ITEMS_IMG_LOADING_COMPLETE:String = "eventItemsImgLoadingComplete";
		
		private const SIDE_MARGIN:int = 14;
		private const CNT_Y_OFFSET:int = 42;
		private const GRP_SPACING:int = 14; // 30
		
		// Fields of app properties
		private var $selectedItem:SquareItem;
		private var $selectedGroup:ItemsGroup;
		private var $events:EventDispatcher;
		private var $loadingActive:Boolean;
		
		private var main:Main;
		private var baseState:StQuantumManager;
		
		private var groups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();
		private var cnt:Sprite;
		private var scb:UIScrollBar;
		private var cropRect:Rectangle;
		private var cntHitBox:Sprite;
		private var selectRect:Shape;
		private var selectTimer:Timer;
		private var centeringOffsetRatio:int;
		private var itemsImgLoadingQueue:Vector.<SquareItem>;
		private var itemsImgLoadingTimer:Timer;
		
		public function GroupsContainer(baseState:StQuantumManager):void
		{
			this.baseState = baseState;
			main = Main.ins;
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			$events = new EventDispatcher();
			
			groups = new Vector.<ItemsGroup>();
			cnt = new Sprite();
			addChild(cnt);
			
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
				// Init items images loading queue
				itemsImgLoadingQueue = new Vector.<SquareItem>();
				itemsImgLoadingTimer = new Timer(Capabilities.isDebugger ? 80 : 100, 0);
				itemsImgLoadingTimer.addEventListener(TimerEvent.TIMER, onItemsImgLoadingTimer);
				
				// Construct groups
				var sizesSum:int = 0;
				
				for each (var itmGrp:ItemsGroup in groups)
				{
					itmGrp.grpCnt = this;
					itmGrp.init();
					
					cnt.addChild(itmGrp.displayObject);
					itmGrp.displayObject.x = SIDE_MARGIN + sizesSum;
					itmGrp.displayObject.y = SIDE_MARGIN;
					sizesSum += itmGrp.realWidth + GRP_SPACING;
				}
				
				sizesSum -= GRP_SPACING;
				
				// Start items images loading queue
				startItemsImgLoadingTimer();
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
			
			addChild(scb);
			scb.update();
			
			scb.addEventListener(ScrollEvent.SCROLL, scroll);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void
			{
				if (!scb.visible) return;
				var wheelRatio:int = 25;
				if (e.delta > 0) wheelRatio = -wheelRatio;
				scb.scrollPosition += -e.delta + wheelRatio;
			});
			
			// Hit box
			cntHitBox = new Sprite();
			cntHitBox.graphics.beginFill(0xF7EBEC, 0);
			cntHitBox.graphics.drawRect(0, 0, cropRect.width, cropRect.height);
			cntHitBox.graphics.endFill();
			cntHitBox.y = CNT_Y_OFFSET;
			addChildAt(cntHitBox, 0);
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
			
			// Select rect
			selectRect = new Shape();
			selectRect.visible = false;
			cnt.addChildAt(selectRect, 0);
			
			// Select timer
			selectTimer = new Timer(2000, 1);
			selectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onSelectTimer);
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
		
		private function scroll(e:Event):void
		{
			var rct:Rectangle = cropRect; /*cnt.scrollRect*/
			rct.x = scb.scrollPosition;
			cnt.scrollRect = rct;
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
		
		private function resetSelected(onlyGroup:Boolean = false):void
		{
			if (selectedGroup != null)
			{
				selectedGroup.selected = false;
				selectedGroup = null;
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
				grp.displayObject.y = SIDE_MARGIN;
				sizesSum += grp.realWidth + GRP_SPACING;
			}
			
			sizesSum -= GRP_SPACING;
			
			//if (selectedGroup != null && selectRect.visible) selectRect.x = selectedGroup.displayObject.x - GRP_SPACING / 2;
			
			var prevScrollPos:Number = scb.scrollPosition;
			scb.maxScrollPosition = calculateMaxScrollPosition(sizesSum);
			scb.update();
			scb.scrollPosition = prevScrollPos;
		
			main.logRed("Max scroll position (rearrange): " + scb.maxScrollPosition);
			main.logRed("Container width (rearrange): " + cnt.width);
		}
		
		private function onSelectTimer(e:TimerEvent):void
		{
			resetSelected(true);
			baseState.grpTitleTextInput.hide();
		}
		
		private const simultaneousLoadingAmout:int = 4;
		
		private function onItemsImgLoadingTimer(e:TimerEvent):void 
		{
			if (itemsImgLoadingQueue.length == 0) {
				itemsImgLoadingTimer.stop();
				trace("Items images loading complete");
				events.dispatchEvent(new Event(EVENT_ITEMS_IMG_LOADING_COMPLETE));
				$loadingActive = false;
				return;
			}
			
			for (var i:int = 0; i < simultaneousLoadingAmout; i++) 
			{	
				if (itemsImgLoadingQueue.length == 0) break;
				var l:int = itemsImgLoadingQueue.length;
				var randomIdx:int = int(Math.random() * ((l-1) - 0 + 1)) + 0;
				var firedItem:SquareItem = itemsImgLoadingQueue[randomIdx];
				firedItem.startLoadingImage();
				itemsImgLoadingQueue.splice(itemsImgLoadingQueue.indexOf(firedItem), 1);
			}
		}
		
		private function moveSelectedGroup(direction:String):void 
		{
			if (selectedGroup == null) return;
			
			var idx:int;
			var idxNext:int;
			
			if (direction == "left") 
			{
				idx = groups.indexOf(selectedGroup);
				idxNext = idx-1;
				if (idxNext < 0) return;
				swapGroups(selectedGroup, groups[idxNext]);
				selectedGroup = selectedGroup;
			}
			
			else
			
			if (direction == "right") 
			{
				idx = groups.indexOf(selectedGroup);
				idxNext = idx+1;
				if (idxNext > groups.length-1) return;
				swapGroups(selectedGroup, groups[idxNext]);
				selectedGroup = selectedGroup;
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
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function selectItem(item:SquareItem):void
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
		}
		
		public function selectGroupWithTimer(grp:ItemsGroup):void
		{
			if (baseState.grpTitleTextInput.focused) return;
			selectGroup(grp);
			baseState.grpTitleTextInput.show(selectedGroup.title);
			if (selectTimer.running) selectTimer.stop();
		}
		
		public function updateUiElementData(elmDataID:String, val:*):void
		{
			switch (elmDataID)
			{
				case "selGrpTitle":
					if (selectedGroup != null) selectedGroup.title = String(val);
					break;
				
				case "selItemCount":
					if (selectedItem != null) selectedItem.count = int(val);
					break;
				
				case "selItemTypeNotes":
					if (selectedItem != null) baseState.notesMgr.setNote(selectedItem.imagePath, String(val));
					break;
			}
		}
		
		public function registerItemsHint(itemsDisOb:InteractiveObject, itemsHintHandler:Function):void
		{
			baseState.hintMgr.registerHintWithHandler(itemsDisOb, itemsHintHandler);
		}
		
		public function addNewGroup():ItemsGroup
		{
			var newGroup:ItemsGroup = new ItemsGroup("", main.settings.getKey(Settings.defaultWarehouse));
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
		}
		
		public function stopSelTimer():void
		{
			if (selectTimer.running) selectTimer.stop();
		}
		
		public function grpTitleInputFocusOut():void
		{
			onSelectTimer(null);
		}
		
		public function selectedGrpButtonMouseOut():void
		{
			if (baseState.grpTitleTextInput.focused) return;
			
			selectTimer.reset();
			selectTimer.start();
		}
		
		public function processDeletedItemAndMoveToUntitledGroup(deletedItem:SquareItem):void 
		{
			var g:ItemsGroup;
			var suchItemExists:Boolean = false; // At least one in all groups space
			
			for each (g in groups) 
			{
				if (g.checkItemExistenceByImgPath(deletedItem.imagePath)) {
					suchItemExists = true;
					break;
				}
			}
			
			if (suchItemExists) return;
			
			var i:int;
			var untitledGroup:ItemsGroup;
			
			for (i = groups.length-1; i >= 0; i--) 
			{	
				g = groups[i];
				if (g.title == "")
				{
					untitledGroup = g;
					break;
				}
			}
			
			if (untitledGroup == null)
			{
				// Create new
				var newUntitledGroup:ItemsGroup = addNewGroup();
				newUntitledGroup.addItem(deletedItem.imagePath);
			}
			else
			{
				// Use found untitled group
				untitledGroup.addItem(deletedItem.imagePath);
			}
		}
		
		public function registerItemForImgLoading(itm:SquareItem):void 
		{
			itemsImgLoadingQueue.push(itm);
		}
		
		public function startItemsImgLoadingTimer():void 
		{
			itemsImgLoadingTimer.start();
			$loadingActive = true;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		public function get selectedItem():SquareItem
		{
			return $selectedItem;
		}
		
		public function set selectedItem(value:SquareItem):void
		{
			$selectedItem = value;
			
			baseState.updateUiElement("selItemCount", value == null ? 0 : value.count);
			baseState.updateUiElement("selItemTypeNotes", value == null ? "" : baseState.notesMgr.getNote(value.imagePath));
			baseState.focusAdrTextArea(value == null ? false : true);
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
				selectRect.graphics.clear();
				selectRect.visible = false;
				return;
			}
			
			// Select rect
			var g:ItemsGroup = value;
			selectRect.graphics.clear();
			selectRect.graphics.beginFill(0xFFDD00, 0.3);
			selectRect.graphics.drawRect(0, 0, g.realWidth + GRP_SPACING, cnt.height);
			selectRect.graphics.endFill();
			selectRect.x = g.displayObject.x - GRP_SPACING / 2;
			//selectRect.y = cnt.y;
			selectRect.visible = true;
		
			//baseState.updateUiElement("selGrpTitle", value == null ? "" : value.title);
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
		
		public function get loadingActive():Boolean 
		{
			return $loadingActive;
		}
	}
}