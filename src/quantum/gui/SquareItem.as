package quantum.gui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import quantum.Main;
	import quantum.data.DataMgr;
	import quantum.events.DataEvent;
	import quantum.gui.modules.GroupsContainer;
	import quantum.product.Product;
	import quantum.product.ProductsMgr;
	
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class SquareItem extends Sprite
	{
		[Embed(source="/../lib/fonts/Montserrat-ExtraBold.ttf",
				fontName = "Montserrat",
				fontFamily = "Montserrat",
				fontWeight = "bold", 
				fontStyle = "normal", 
				mimeType = "application/x-font",
				advancedAntiAliasing = "true",
				embedAsCFF = "false")]
		private var FontMontserratBold:Class;
		
		public static const SQUARE_SIZE:int = 40; // Def: 68 58
		
		private const DEF_COUNT_VALUE:int = 1;
		
		// Fields of data properties
		private var $count:int;
		private var $productID:int;
		private var $imagePath:String; // Cached value of product's image file path 
		
		// Fields of app properties
		private var $dataXml:XML;
		private var $selected:Boolean;
		private var $parentItemsGroup:ItemsGroup;
		
		private var main:Main;
		private var grpCnt:GroupsContainer;
		private var pm:ProductsMgr;
		
		private var imageBitmap:Bitmap;
		private var $frame:Shape; // Top frame of the square
		private var overFrame:Shape;
		private var selectedFrame:Sprite;
		private var hitBox:Sprite;
		private var triangles:Sprite;
		private var countTextField:TextField;
		private var priceCorner:Shape;
		private var weightCorner:Shape;
		private var selectFrameAnimation:MovieClip;
		
		public function SquareItem(productID:int, count:int):void
		{
			this.productID = productID;
			this.count = count == 0 ? DEF_COUNT_VALUE : count;
			
			main = Main.ins;
		}
		
		public function init():void
		{
			grpCnt = parentItemsGroup.grpCnt;
			pm = main.stQuantumMgr.productsMgr;
			imagePath = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_imgFile) as String; // Cache image path
			
			var w:int;
			var h:int;
			w = h = SQUARE_SIZE;
			
			// Main frame
			$frame = new Shape();
			$frame.graphics.lineStyle(1, 0xB7BABC, 1, true, "normal", CapsStyle.SQUARE, JointStyle.MITER);
			$frame.graphics.drawRect(0, 0, w-1, h-1);
			
			// Over frame
			overFrame = new Shape();
			overFrame.graphics.beginFill(0xFFFFFF, 0.3);
			overFrame.graphics.drawRect(0, 0, w-1, h-1);
			overFrame.graphics.endFill();
			
			// Selected frame
			selectedFrame = new Sprite();
			
			// Selection animation
			selectFrameAnimation = new SelectFrameAnimation();
			selectFrameAnimation.width = SQUARE_SIZE;
			selectFrameAnimation.height = SQUARE_SIZE;
			
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
			
			// Count text field
			countTextField = new TextField();
			countTextField.defaultTextFormat = new TextFormat("Montserrat", 14, 0xFFFFFF, true);
			countTextField.embedFonts = true;
			countTextField.antiAliasType = AntiAliasType.ADVANCED;
			countTextField.autoSize = TextFieldAutoSize.RIGHT;
			countTextField.filters = [new GlowFilter(0, 1, 2, 2, 2)];
			countTextField.width = 20;
			countTextField.text = String(count);
			countTextField.cacheAsBitmap = true;
			
			// Hint corner
			/*
			hintCorner = new Shape();
			hintCorner.graphics.beginFill(0xED1614);
			hintCorner.graphics.moveTo(10, 0);
			hintCorner.graphics.lineTo(0, 0);
			hintCorner.graphics.lineTo(0, 10);
			hintCorner.graphics.lineTo(10, 0);
			hintCorner.graphics.endFill();
			hintCorner.filters = [new DropShadowFilter(1, 45, 0, 0.3, 1, 1, 1)];
			*/
			
			// Price corner
			priceCorner = new Shape();
			priceCorner.graphics.beginFill(0xED1614); // 0x0046FE — blue
			priceCorner.graphics.moveTo(0, 0);
			priceCorner.graphics.lineTo(10, 0);
			priceCorner.graphics.lineTo(10, 10);
			priceCorner.graphics.lineTo(0, 0);
			priceCorner.graphics.endFill();
			priceCorner.filters = [new DropShadowFilter(1, 135, 0, 0.3, 1, 1, 1)];
			priceCorner.x = w - priceCorner.width;
			
			// Weight corner
			weightCorner = new Shape();
			weightCorner.graphics.beginFill(0xED1614);
			weightCorner.graphics.moveTo(0, h);
			weightCorner.graphics.lineTo(10, h);
			weightCorner.graphics.lineTo(0, h-10);
			weightCorner.graphics.lineTo(0, h);
			weightCorner.graphics.endFill();
			weightCorner.filters = [new DropShadowFilter(1, -45, 0, 0.3, 1, 1, 1)];
			weightCorner.y = 0;
						
			// Image bitmap
			imageBitmap = new Bitmap();
			imageBitmap.smoothing = true;
			imageBitmap.cacheAsBitmap = true;
			
			// Display order
			addChild(imageBitmap);
			addChild(selectedFrame);
			addChild(overFrame);
			addChild(priceCorner);
			addChild(weightCorner);
			addChild(triangles);
			addChild(countTextField);
			addChild($frame);
			addChild(hitBox);
			
			// Elements settings
			overFrame.visible = false;
			selectedFrame.visible = false;
			
			if (pm.opProduct(productID, DataMgr.OP_READ, Product.prop_price) == 0)
			{
				priceCorner.visible = false;
			}
			
			if (pm.opProduct(productID, DataMgr.OP_READ, Product.prop_weight) == 0)
			{
				weightCorner.visible = false;
			}
			
			pm.events.addEventListener(DataEvent.DATA_UPDATE, associatedProductDataUpdated);
			
			countTextField.y = SQUARE_SIZE - countTextField.height + 2;
			countTextField.x = SQUARE_SIZE - countTextField.width - 1;
			countTextField.mouseEnabled = false;
			
			// Listeners
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
			
			checkImage();
		}
		
		/**
		 * Common handler for associated product data updates
		 */
		private function associatedProductDataUpdated(e:DataEvent):void 
		{
			if (e.entityId != productID) return; // If not our product > dismiss
			
			if (e.updatedFieldName == Product.prop_price) 
			{
				pm.opProduct(productID, DataMgr.OP_READ, Product.prop_price) == 0 ?
					priceCorner.visible = false : priceCorner.visible = true;
			}
			
			else
			
			if (e.updatedFieldName == Product.prop_weight) 
			{
				pm.opProduct(productID, DataMgr.OP_READ, Product.prop_weight) == 0 ?
					weightCorner.visible = false : weightCorner.visible = true;
			}
			
			else
			
			if (e.updatedFieldName == Product.prop_image) 
			{
				checkImage();
			}
		}
		
		private function checkImage():void 
		{
			var bmd:BitmapData = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_image) as BitmapData;
			
			if (bmd == null) 
				return;
			
			if (imageBitmap.bitmapData != null) imageBitmap.bitmapData.dispose();
			imageBitmap.bitmapData = bmd;
		}
		
		private function hitBoxClick(e:MouseEvent):void
		{
			if (!selected)
				return;
			
			var halfSize:int = hitBox.height / 2;
			
			if (e.localY < halfSize)
			{
				count++;
			}
			
			else
				
			if (e.localY >= halfSize)
			{
				count--;
			}
		}
		
		private function onMouseClick(e:MouseEvent):void
		{
			if (stage == null) return; // [Fix] if item just has been deleted, don't select it
			grpCnt.selectItem(this);
		}
		
		private function onMouseOver(e:MouseEvent):void
		{
			if (selected)
			{
				triangles.visible = true;
				return;
			}
			
			overFrame.visible = true;
		}
		
		private function onMouseOut(e:MouseEvent):void
		{
			if (selected)
			{
				triangles.visible = false;
			}
			
			overFrame.visible = false;
		}
		
		/**
		 * PUBLIC INTERFACE
		 * ================================================================================
		 */
		
		public function remove():void
		{
			parentItemsGroup.removeItem(this);
		}
		
		public function hintTextHandler():String
		{
			var sku:String = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_sku);
			var price:* = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_price);
			var weight:* = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_weight);
			var note:String = pm.opProduct(productID, DataMgr.OP_READ, Product.prop_note);
			var inStockFullCount:int = grpCnt.getProductFullCount(productID);
			var inStockFullCountStr:String;
			var hintOutput:String;
			
			sku = sku == "" ? main.stQuantumMgr.colorText(Colors.WARN, "[SKU не указан]") : sku;
			note = note != "" ? "\n" + "<b>Заметка</b>\n" + note : "";
						
			inStockFullCountStr = 
				"<b>В наличии:</b> " + inStockFullCount.toString() + (inStockFullCount == 1 ? " (последняя)" : "");
			
			if (inStockFullCount == 1)
			{
				inStockFullCountStr = main.stQuantumMgr.colorText(Colors.WARN, inStockFullCountStr);
			}
			else 
			if (inStockFullCount == 0)
			{
				inStockFullCountStr = main.stQuantumMgr.colorText(Colors.TXLB_LIGHT_GREY, "Нет в наличии");
			}
				
			if (price == 0 && weight == 0) 
			{
				hintOutput = sku + "\n" + inStockFullCountStr + note;
			}
			
			else 
			{
				var useGramForWeight:Boolean = false;
				if (Number(weight) < 1)
				{
					useGramForWeight = true;
					weight *= 1000;
				}
								
				price = price == 0 ? main.stQuantumMgr.colorText(Colors.TXLB_LIGHT_GREY, "[Цена не указана]") : 
					"<b>Цена:</b> $" + (main.numFrm.formatNumber(price) as String);
					
				weight = weight == 0 ? main.stQuantumMgr.colorText(Colors.TXLB_LIGHT_GREY, "[Вес не указан]") : 
					"<b>Вес:</b> " + (main.numFrm.formatNumber(weight) as String) + " " + (useGramForWeight ? "г" : "кг");
					
				hintOutput = sku + "\n" + price + "\n" + weight + "\n" + inStockFullCountStr + note;
			}
			
			return hintOutput;
		}
		
		/**
		 * PROPERTIES
		 * ================================================================================
		 */
		
		/**
		 * Количество
		 */
		public function get count():int
		{
			return $count;
		}
		
		public function set count(value:int):void
		{
			
			$count = value;
			
			if (value <= 0)
			{
				remove();
				return;
			}
			
			if (main != null) main.dataMgr.opItem(this, DataMgr.OP_UPDATE, "count", value);
			if (selected) main.stQuantumMgr.updateUiElement("selItemCount", count);
			
			if (countTextField != null) countTextField.text = String(value);
		}
		
		/**
		 * Путь до оригинальной картинки в файловой системе (кэшированное значение)
		 */
		public function get imagePath():String
		{
			return $imagePath;
		}
		
		public function set imagePath(value:String):void
		{
			$imagePath = value;
		}
		
		/**
		 * Идентификатор связанного товара
		 */
		public function get productID():int 
		{
			return $productID;
		}
		
		public function set productID(value:int):void 
		{
			$productID = value;
		}
		
		// ================================================================================

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
			
			if (value == true)
			{
				selectedFrame.visible = true;
				
				if (selectedFrame.numChildren == 0)
					selectedFrame.addChild(selectFrameAnimation);
				
				overFrame.visible = false;
				triangles.visible = true;
			}
			
			else
			{
				selectedFrame.visible = false;
				
				if (selectedFrame.numChildren > 0)
					selectedFrame.removeChildAt(0);
			}
		}
		
		public function get frame():Shape
		{
			return $frame;
		}
		
		public function get parentItemsGroup():ItemsGroup
		{
			return $parentItemsGroup;
		}
		
		public function set parentItemsGroup(value:ItemsGroup):void
		{
			$parentItemsGroup = value;
		}
		
		public function get dataXml():XML
		{
			return $dataXml;
		}
		
		public function set dataXml(value:XML):void
		{
			$dataXml = value;
		}
	}
}