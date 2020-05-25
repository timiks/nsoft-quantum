package quantum.gui.elements 
{
	import fl.controls.Button;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import quantum.Main;
	import quantum.events.EbayHubEvent;
	import quantum.gui.Colors;
		
	/**
	 * ...
	 * @author Tim Yusupov
	 */
	public class EbayOrdersCheckButton 
	{
		private static const buttonStandbyUiTitle:String = "Запросить инфу о заказах у Ибея";
		private static const buttonCheckInProgressUiTitle:String = "Запрос заказов выполняется...";
		private static const buttonUnableUiTitle:String = "Операция недоступна";
		private static const buttonNoCheckStartConfirmationUiTitle:String = "Внутренняя ошибка";
		private static const buttonCheckErrorUiTitle:String = "Не вышло";
		
		private static const state_unable:int = 1;
		private static const state_standby:int = 2;
		private static const state_inProgress:int = 3;
		private static const state_showingMessage:int = 4;
		
		private var main:Main;
		
		private var btn:Button;
		
		private var currentState:int;
		
		private var tmrCheckExecutionStartConfirmationWaitTimeout:Timer; // Confirmation wait timeout
		private var tmrMessageShowDelay:Timer; // Message show delay
		private var tmrCheckProcessFinishWaitTimeout:Timer; // Check process complete wait timeout
		
		public function EbayOrdersCheckButton(controlButton:Button):void 
		{
			btn = controlButton;
		}
		
		public function init():void 
		{
			main = Main.ins;
			
			tmrCheckExecutionStartConfirmationWaitTimeout = new Timer(8000, 1); // 8 secs
			tmrCheckExecutionStartConfirmationWaitTimeout.addEventListener(TimerEvent.TIMER_COMPLETE, onConfirmationWatTimeout);
			
			tmrMessageShowDelay = new Timer(4000, 1); // 4 secs
			tmrMessageShowDelay.addEventListener(TimerEvent.TIMER_COMPLETE, onMessageShowComplete);
			
			tmrCheckProcessFinishWaitTimeout = new Timer(70000, 1); // 70 secs
			tmrCheckProcessFinishWaitTimeout.addEventListener(TimerEvent.TIMER_COMPLETE, onCheckProcessFinishWaitTimeout);
			
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_START_CONFIRMATION_RECEIVED, onConfirmationReceived);
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_SUCCESS, onCheckSuccess);
			main.ebayHub.events.addEventListener(EbayHubEvent.ORDERS_CHECK_ERROR, onCheckError);
			main.ebayHub.events.addEventListener(EbayHubEvent.USER_AUTH_TOKEN_ERROR, onUnable);
			main.ebayHub.events.addEventListener(EbayHubEvent.PROCESS_RESTART_OVERFLOW, onUnable);
			main.ebayHub.events.addEventListener(EbayHubEvent.PROCESS_COM_ERROR, onUnable);
			main.ebayHub.events.addEventListener(EbayHubEvent.PROCESS_SYS_ERROR, onUnable);
			main.ebayHub.events.addEventListener(EbayHubEvent.PROCESS_FILE_NOT_FOUND, onUnable);
			
			btn.addEventListener(MouseEvent.CLICK, buttonClick);
			
			setState(state_standby);
		}
		
		private function onUnable(e:EbayHubEvent):void 
		{
			setState(state_unable);
			
			if (e.type == EbayHubEvent.PROCESS_FILE_NOT_FOUND)
				main.qnMgrGim.infoPanel.showMessage("Не найден дочерний файл программы для работы с Ибеем", Colors.BAD);
		}
		
		private function buttonClick(e:MouseEvent):void 
		{
			if (main.ebayHub.processFileNotFound)
			{ 
				setState(state_unable);
				main.qnMgrGim.infoPanel.showMessage("Не найден дочерний файл программы для работы с Ибеем", Colors.BAD);
				return;
			}
			
			setState(state_inProgress);
			
			main.ebayHub.SendCheckSignal();
			
			// Confirmation wait timeout
			tmrCheckExecutionStartConfirmationWaitTimeout.start();
		}
		
		// Got confirmation
		private function onConfirmationReceived(e:EbayHubEvent):void 
		{
			tmrCheckExecutionStartConfirmationWaitTimeout.reset(); // Stop timeout
			tmrCheckProcessFinishWaitTimeout.start();
			
			if (currentState != state_inProgress)
				setState(state_inProgress);
		}
		
		// Confirmation wait timeout — no confirmation
		private function onConfirmationWatTimeout(e:TimerEvent):void 
		{
			showMessage(buttonNoCheckStartConfirmationUiTitle);
		}
		
		// Check process finish and results
		private function onCheckSuccess(e:EbayHubEvent):void 
		{
			tmrCheckProcessFinishWaitTimeout.reset(); // stop timeout
			
			var resultMessage:String;
			
			if (e.storeNewEntries == 0)
				resultMessage = "Всё актуально!";
			else
				resultMessage = "Успешно. Пополнение: +" + e.storeNewEntries;
			
			showMessage(resultMessage);
		}
		
		// Check error
		private function onCheckError(e:EbayHubEvent):void 
		{
			tmrCheckProcessFinishWaitTimeout.reset(); // stop timeout
			
			showMessage(buttonCheckErrorUiTitle);
			main.qnMgrGim.infoPanel.showMessage("Не вышло обновить информацию о заказах с Ибея", Colors.WARN);
		}
		
		// Check process wait timeout
		private function onCheckProcessFinishWaitTimeout(e:TimerEvent):void 
		{
			showMessage("Истекло время ожидания");
		}
		
		// Message show finish
		private function onMessageShowComplete(e:TimerEvent):void 
		{
			setState(state_standby);
		}
		
		private function setState(stateCode:int):void 
		{
			if (stateCode == currentState)
				return;
			
			if (stateCode == state_standby) 
			{
				btn.label = buttonStandbyUiTitle;
				btn.enabled = true;
			}
			else if (stateCode == state_inProgress)
			{
				btn.label = buttonCheckInProgressUiTitle;
				btn.enabled = false;
			}
			else if (stateCode == state_unable)
			{
				btn.addEventListener(MouseEvent.CLICK, buttonClick);
				btn.label = buttonUnableUiTitle;
				btn.enabled = false;
			}
			
			currentState = stateCode;
		}
		
		private function showMessage(theMessage:String):void 
		{
			btn.label = theMessage;
			btn.enabled = true;
			setState(state_showingMessage);
			tmrMessageShowDelay.start();
		}
	}
}