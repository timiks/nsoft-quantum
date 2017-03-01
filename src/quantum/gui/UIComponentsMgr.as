package quantum.gui {

	import fl.controls.List;
	import fl.core.UIComponent;
	import flash.text.TextFormat;

	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class UIComponentsMgr {

		private var defTextFormat:TextFormat;

		public function UIComponentsMgr():void {

			defTextFormat = new TextFormat("Tahoma", 12);

		}

		public function setStyle(uiComponent:UIComponent):void {

			if (uiComponent is List) {

				(uiComponent as List).setRendererStyle("textFormat", defTextFormat);
				(uiComponent as List).setRendererStyle("disabledTextFormat", defTextFormat);
				return;

			}

			uiComponent.setStyle("textFormat", defTextFormat);
			uiComponent.setStyle("disabledTextFormat", defTextFormat);

		}

	}

}