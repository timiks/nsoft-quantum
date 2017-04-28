package quantum.gui {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GraphicsStroke;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import quantum.data.DataMgr;
	import quantum.Main;
	import sk.yoz.image.ImageResizer;
	import sk.yoz.math.ResizeMath;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class SquareItem extends Sprite {

		private const DEF_COUNT_VALUE:int = 1;
		private const SQUARE_SIZE:int = 40; // Def: 68 58

		// App properties
		private var $position:int;
		private var $imageCacheID:int;
		private var $selected:Boolean;
		private var $parentItemsGroup:ItemsGroup;
		private var $dataXml:XML;

		// Data properties
		private var $id:int;
		private var $count:int;
		private var $imagePath:String;
		private var $details:String;

		private var ldr:Loader; // Internal Loader for image
		private var ba:ByteArray;

		private var $frame:Shape; // Top frame of the square
		private var imgMask:Shape;
		private var overFrame:Shape;
		private var selectedFrame:Shape;
		private var errorFrame:Shape;
		private var hitBox:Sprite;
		private var triangles:Sprite;
		private var countTextField:TextField;
		private var hintCircle:Shape;

		private var imgFile:File;
		private var fst:FileStream;

		private var main:Main;
		private var grpCnt:GroupsContainer;

		public function SquareItem(imgPath:String, count:int, details:String = ""):void {

			this.imagePath = imgPath;
			this.count = count == 0 ? DEF_COUNT_VALUE : count;
			this.details = details;

			main = Main.ins;

		}

		public function init():void {

			grpCnt = parentItemsGroup.grpCnt;

			var w:int;
			var h:int;
			w = h = SQUARE_SIZE;

			// Frame
			$frame = new Shape();
			$frame.graphics.lineStyle(1, 0xB7BABC);
			$frame.graphics.drawRect(0, 0, w-1, h-1);
			//$frame.graphics.lineTo(w, 0);
			//$frame.graphics.lineTo(w, h);
			//$frame.graphics.lineTo(0, h);
			//$frame.graphics.lineTo(0, 0);

			// Over frame
			overFrame = new Shape();
			overFrame.graphics.beginFill(0xFFFFFF, 0.3);
			overFrame.graphics.drawRect(0, 0, w-1, h-1);
			overFrame.graphics.endFill();

			// Selected frame
			selectedFrame = new Shape();
			selectedFrame.graphics.beginFill(0x2D5DE0, 0.5);
			selectedFrame.graphics.drawRect(0, 0, w-1, h-1);
			selectedFrame.graphics.endFill();

			// Error frame
			errorFrame = new Shape();
			errorFrame.graphics.beginFill(0xE10044, 0.7);
			errorFrame.graphics.drawRect(0, 0, w-1, h-1);
			errorFrame.graphics.endFill();

			// Hit box
			hitBox = new Sprite();
			hitBox.graphics.beginFill(0xFFFFFF, 0);
			hitBox.graphics.drawRect(0, 0, w-1, h-1);
			hitBox.graphics.endFill();

			// Triangles
			triangles = new Sprite();
			triangles.mouseEnabled = false;
			triangles.mouseChildren = false;
			triangles.visible = false;

			var triang:MovieClip = new Triangle();
			triang.x = (hitBox.width / 2) - (triang.width / 2);
			triang.y = (hitBox.height / 4) - (triang.height / 2);
			triangles.addChild(triang);

			triang = new Triangle();
			triang.gotoAndStop(2);
			triang.x = (hitBox.width / 2) - (triang.width / 2);
			triang.y = (hitBox.height / 4 * 3) - (triang.height / 2);
			triangles.addChild(triang);

			// Image mask
			imgMask = new Shape();
			imgMask.graphics.beginFill(0xCCCC3F, 1);
			imgMask.graphics.drawRect(0, 0, w-1, h-1);
			imgMask.graphics.endFill();

			// Count text field
			countTextField = new TextField();
			countTextField.defaultTextFormat = new TextFormat("Tahoma", 14, 0xFFFFFF, true); // Def size: 20 18 14
			countTextField.filters = [new GlowFilter(0, 1, 2, 2, 2)];
			countTextField.antiAliasType = AntiAliasType.ADVANCED;
			countTextField.autoSize = TextFieldAutoSize.RIGHT;
			countTextField.width = 20;
			countTextField.text = String(count);
			countTextField.cacheAsBitmap = true;

			// Hint circle
			hintCircle = new Shape();
			hintCircle.graphics.beginFill(0xD3ED1A);
			hintCircle.graphics.drawEllipse(0, 0, 8, 8);
			hintCircle.graphics.endFill();
			hintCircle.filters = [new DropShadowFilter(1, 45, 0, 0.5, 1, 1, 1)];
			hintCircle.x = 2;
			hintCircle.y = 2;

			// Functional stuff
			ldr = new Loader();
			ba = new ByteArray();
			fst = new FileStream();
			imgFile = new File(imagePath);

			// Display order
			addChild(ldr);
			addChild(imgMask);
			addChild(errorFrame);
			addChild(selectedFrame);
			addChild(overFrame);
			addChild(hintCircle);
			addChild(triangles);
			addChild(countTextField);
			addChild($frame);
			addChild(hitBox);

			// Elements settings
			overFrame.visible = false;
			selectedFrame.visible = false;
			errorFrame.visible = false;
			imgMask.visible = false;

			if (details == "")
				hintCircle.visible = false;

			countTextField.y = SQUARE_SIZE - countTextField.height + 2;
			countTextField.x = SQUARE_SIZE - countTextField.width - 1;
			countTextField.mouseEnabled = false;

			// Listeners
			fst.addEventListener(Event.COMPLETE, onImgLoad);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(MouseEvent.CLICK, onMouseClick);
			hitBox.addEventListener(MouseEvent.CLICK, hitBoxClick);

			// General settings
			buttonMode = true;
			tabEnabled = false;
			tabChildren = false;
			focusRect = false;
			cacheAsBitmap = true;

			// Hint
			grpCnt.registerItemsHint(this, hintTextHandler);

			// Start loading image
			fst.openAsync(imgFile, FileMode.READ);
			fst.addEventListener(IOErrorEvent.IO_ERROR, ioError);

		}

		private function ioError(e:IOErrorEvent):void {
			errorFrame.visible = true;
		}

		private function onImgLoad(e:Event):void {

			fst.readBytes(ba, 0, fst.bytesAvailable);
			fst.close();
			ldr.loadBytes(ba);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {

				var img:Bitmap = ldr.content as Bitmap;
				img.smoothing = true;
				ldr.cacheAsBitmap = true;

				var w:int, h:int;
				var resizedMatrix:BitmapData;
				var minSide:Number = Math.min(ldr.width, ldr.height);

				// Calculate image size for box with preserved Aspect Ratio
				if (ldr.width == minSide) {

					h = SQUARE_SIZE * ldr.height / ldr.width; // W * scrH / scrW
					w = SQUARE_SIZE;

				} else {

					w = ldr.width * SQUARE_SIZE / ldr.height; // srcW * H / srcH
					h = SQUARE_SIZE;

				}

				// Resize image using Bilinear Interpolation algorithm
				resizedMatrix = ImageResizer.bilinearIterative(img.bitmapData, w, h, ResizeMath.METHOD_PAN_AND_SCAN);
				img.bitmapData.dispose();
				img.bitmapData = resizedMatrix;

				// Centering offset for horizontal image
				if (h < w) ldr.x -= (ldr.width - frame.width) / 2;

				// Set mask
				ldr.mask = imgMask;
				imgMask.visible = true;

				//parentItemsGroup.loadNext();

			});

		}

		private function hitBoxClick(e:MouseEvent):void {

			if (!selected) return;

			var halfSize:int = hitBox.height / 2;

			if (e.localY < halfSize) {
				count++;
			}

			else

			if (e.localY >= halfSize) {
				count--;
			}

		}

		private function onMouseClick(e:MouseEvent):void {
			if (stage == null) return; // [Fix] if item just has been deleted, don't select it
			grpCnt.selectItem(this);
		}

		private function onMouseOver(e:MouseEvent):void {

			if (selected) {

				triangles.visible = true;
				return;

			}

			overFrame.visible = true;
		}

		private function onMouseOut(e:MouseEvent):void {

			if (selected) {

				triangles.visible = false;

			}

			overFrame.visible = false;
		}

		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */

		public function remove():void {
			parentItemsGroup.removeItem(this);
		}

		public function startLoadingImage():void {
			fst.openAsync(imgFile, FileMode.READ);
		}

		public function hintTextHandler():String {

			if (details == null || details == "") {
				return null;
			}

			return details;

		}

		/**
		 * PROPERTIES
		 * ================================================================================
		 */

		//{ region Properties

		/**
		 * Идентификатор этого объекта
		 */
		public function get id():int {
			return $id;
		}

		public function set id(value:int):void {
			$id = value;
		}

		/**
		 * Количество
		 */
		public function get count():int {
			return $count;
		}

		public function set count(value:int):void {

			$count = value;

			if (value <= 0) {
				remove();
				return;
			}

			if (main != null) main.dataMgr.opItem(this, DataMgr.OP_UPDATE, "count", value);
			if (selected) main.stQuantumMgr.updateUiElement("selItemCount", count);

			if (countTextField != null) countTextField.text = String(value);

		}

		/**
		 * Путь до оригинальной картинки в файловой системе
		 */
		public function get imagePath():String {
			return $imagePath;
		}

		public function set imagePath(value:String):void {
			$imagePath = value;
		}

		public function get details():String {
			return $details;
		}

		public function set details(value:String):void {

			$details = value;

			if ($details == "") {
				if (hintCircle != null) hintCircle.visible = false;
			}
			else {
				if (hintCircle != null) hintCircle.visible = true;
			}

			if (main != null) main.dataMgr.opItem(this, DataMgr.OP_UPDATE, "details", value);
			if (selected) main.stQuantumMgr.updateUiElement("selItemDetails", details);

		}

		// ================================================================================

		/**
		 * Порядковый номер в группе
		 */
		public function get position():int {
			return $position;
		}

		public function set position(value:int):void {
			$position = value;
		}

		/**
		 * Идентификатор превьюшки картинки в кэше (AppData)
		 */
		public function get imageCacheID():int {
			return $imageCacheID;
		}

		public function set imageCacheID(value:int):void {
			$imageCacheID = value;
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
				selectedFrame.visible = true;
				overFrame.visible = false;
				triangles.visible = true;
			} else {
				selectedFrame.visible = false;
			}
		}

		public function get frame():Shape {
			return $frame;
		}

		public function get parentItemsGroup():ItemsGroup {
			return $parentItemsGroup;
		}

		public function set parentItemsGroup(value:ItemsGroup):void {
			$parentItemsGroup = value;
		}

		public function get dataXml():XML {
			return $dataXml;
		}

		public function set dataXml(value:XML):void {
			$dataXml = value;
		}

		//} endregion

	}

}