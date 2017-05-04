package quantum.gui {

	import fl.controls.UIScrollBar;
	import fl.events.ScrollEvent;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import quantum.data.DataMgr;
	import quantum.Main;
	import quantum.Settings;
	import quantum.states.StQuantumManager;
	import quantum.Warehouse;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class GroupsContainer extends Sprite {

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

		private var $selectedItem:SquareItem;
		private var $selectedGroup:ItemsGroup;

		private const SIDE_MARGIN:int = 14;
		private const CNT_Y_OFFSET:int = 42;
		private const GRP_SPACING:int = 14; // 30

		public function GroupsContainer(baseState:StQuantumManager):void {
			this.baseState = baseState;
			main = Main.ins;
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void {

			removeEventListener(Event.ADDED_TO_STAGE, init);

			groups = new Vector.<ItemsGroup>();
			cnt = new Sprite();
			addChild(cnt);

			cnt.y = CNT_Y_OFFSET;
			focusRect = false;

			// Load groups
			groups = main.dataMgr.getAllGroups();

			if (groups.length == 0) {

				main.logRed("No groups found");

			} else {

				// Construct groups
				var sizesSum:int = 0;

				for each (var itmGrp:ItemsGroup in groups) {

					itmGrp.grpCnt = this;
					itmGrp.init();

					cnt.addChild(itmGrp.displayObject);
					itmGrp.displayObject.x = SIDE_MARGIN + sizesSum;
					itmGrp.displayObject.y = SIDE_MARGIN;
					sizesSum += itmGrp.realWidth + GRP_SPACING;

				}

				sizesSum -= GRP_SPACING;

			}

			// Scroll
			cropRect = new Rectangle(0, 0, stage.stageWidth, 538);
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
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):void {
					if (!scb.visible) return;
					var ratio:int = 25;
					if (e.delta > 0) ratio = -ratio
					scb.scrollPosition += -e.delta + ratio;
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
			if (main.settings.getKey(Settings.deleteEmptyGroupsOnStartup)) {

				var emptyGroups:Vector.<ItemsGroup> = new Vector.<ItemsGroup>();
				for each (var grp:ItemsGroup in groups) {
					if (grp.empty) {
						emptyGroups.push(grp);
					}
				}

				if (emptyGroups.length > 0) {

					for each (var emptyGrp:ItemsGroup in emptyGroups) {
						removeGroup(emptyGrp);
						trace("EMPTY GROUP REMOVED");
					}

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

		private function keyDown(e:KeyboardEvent):void {

			// DELETE
			if (e.keyCode == Keyboard.DELETE) {

				/* Feature 'Delete by pressing Del key' is removed due to using Del key in text editing
				if (stage.focus == baseState.tableDataComposer.adrInputTextArea.textField) return;
				if (selectedItem != null) selectedItem.remove();
				*/

			}

			else

			// F8
			if (e.keyCode == Keyboard.F8) {

				compositionChanged();

			}

		}

		private function cntHitBoxClick(e:MouseEvent):void {

			resetSelected();

			if (baseState.grpTitleTextInput.tf.visible && !baseState.grpTitleTextInput.focused)
				baseState.grpTitleTextInput.hide();

			stage.focus = this;

		}

		private function scroll(e:Event):void {
			var rct:Rectangle = cropRect; /*cnt.scrollRect*/
			rct.x = scb.scrollPosition;
			cnt.scrollRect = rct;
		}

		private function calculateMaxScrollPosition(groupsSizesSum:Number):Number {

			cnt.scrollRect = null;

			var bd:BitmapData = new BitmapData(1, 1, false);
			bd.draw(cnt);
			bd.dispose();

			var msp:Number = (/*cnt.width*/ groupsSizesSum - cropRect.width) + (SIDE_MARGIN * 2);

			cnt.scrollRect = cropRect;
			scb.visible = msp > 0 ? true : false;

			return msp;

		}

		private function resetSelected(onlyGroup:Boolean = false):void {

			if (selectedGroup != null) {
				selectedGroup.selected = false;
				selectedGroup = null;
			}

			if (onlyGroup) return;

			if (selectedItem != null) {
				selectedItem.selected = false;
				selectedItem = null;
			}

		}

		private function rearrange():void {

			var sizesSum:int = 0;
			for each (var grp:ItemsGroup in groups) {
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

			/*
			// Centering
			if (sizesSum < cropRect.width) {
				centeringOffsetRatio = (cropRect.width - sizesSum) / 2;
				for each (var grp:ItemsGroup in groups) {
					grp.displayObject.x = grp.displayObject.x - SIDE_MARGIN + centeringOffsetRatio;
				}
			}
			*/

			main.logRed("Max scroll position (rearrange): " + scb.maxScrollPosition);
			main.logRed("Container width (rearrange): " + cnt.width);

		}

		private function onSelectTimer(e:TimerEvent):void {
			resetSelected(true);
			baseState.grpTitleTextInput.hide();
		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function selectItem(item:SquareItem):void {

			if (selectedItem != null && selectedItem !== item)
				selectedItem.selected = false;

			selectedItem = item;
			selectedItem.selected = true;

			baseState.tableDataComposer.launchAdrProcessing();

		}

		public function selectGroup(grp:ItemsGroup):void {

			if (baseState.grpTitleTextInput.focused) return;

			if (selectedGroup != null && selectedGroup !== grp)
				selectedGroup.selected = false;

			selectedGroup = grp;
			selectedGroup.selected = true;

			baseState.grpTitleTextInput.show(selectedGroup.title);

			if (selectTimer.running) selectTimer.stop();

		}

		public function updateUiElementData(elmDataID:String, val:*):void {

			switch (elmDataID) {

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

		public function registerItemsHint(itemsDisOb:InteractiveObject, itemsHintHandler:Function):void {

			baseState.hintMgr.registerHintWithHandler(itemsDisOb, itemsHintHandler);

		}

		public function addNewGroup():void {

			var newGroup:ItemsGroup = new ItemsGroup("", main.settings.getKey(Settings.defaultWarehouse));
			main.dataMgr.opGroup(newGroup, DataMgr.OP_ADD);
			groups.push(newGroup);
			newGroup.grpCnt = this;
			newGroup.brandNew = true;
			newGroup.init();
			cnt.addChild(newGroup.displayObject);
			compositionChanged();

			if(scb.maxScrollPosition > 0) scb.scrollPosition = scb.maxScrollPosition;

		}

		public function removeGroup(removingGroup:ItemsGroup):void {

			trace("REMOVING GROUP");
			main.dataMgr.opGroup(removingGroup, DataMgr.OP_REMOVE);
			cnt.removeChild(removingGroup.displayObject);
			groups.splice(groups.indexOf(removingGroup), 1);
			compositionChanged();

		}

		public function itemRemoved():void {
			resetSelected();
			compositionChanged();
		}

		public function compositionChanged():void {
			rearrange();
		}

		public function stopSelTimer():void {
			if (selectTimer.running) selectTimer.stop();
		}

		public function grpTitleInputFocusOut():void {
			onSelectTimer(null);
		}

		public function selectedGrpButtonMouseOut():void {

			if (baseState.grpTitleTextInput.focused) return;

			selectTimer.reset();
			selectTimer.start();

		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		public function get selectedItem():SquareItem {
			return $selectedItem;
		}

		public function set selectedItem(value:SquareItem):void {
			$selectedItem = value;

			baseState.updateUiElement("selItemCount", value == null ? 0 : value.count);
			baseState.updateUiElement("selItemTypeNotes", value == null ? "" : baseState.notesMgr.getNote(value.imagePath));
			baseState.focusAdrTextArea(value == null ? false : true);
		}

		public function get selectedGroup():ItemsGroup {
			return $selectedGroup;
		}

		public function set selectedGroup(value:ItemsGroup):void {
			$selectedGroup = value;

			if (value == null) {
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

	}

}