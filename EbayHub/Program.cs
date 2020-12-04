using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Newtonsoft.Json;

namespace Quantum.EbayHub
{
    class Program
    {
        static Process parentProcess;
        static HiddenForm activeHiddenForm;

        // Entry point
        [STAThread]
        static void Main(string[] args)
        {
            // Invalid launch protection
#if (!DEBUG)
            if (args.Length < 1)
                Exit();

            if (args[0] != "run")
                Exit();

            Process[] processQuery;

            // Check whether same active processes exist > and kill 'em if they do
            //processQuery = Process.GetProcessesByName(Process.GetCurrentProcess().ProcessName);
            //if (processQuery.Length > 1)
            //    foreach (Process p in processQuery)
            //        p.Kill();

            if (args.Length == 2)
            {
                string parentProcessName = args[1];

                processQuery = Process.GetProcessesByName(parentProcessName);
                if (processQuery.Length == 0)
                    // No parent process found
                    Exit();
                else
                {
                    parentProcess = processQuery[0];
                    parentProcess.EnableRaisingEvents = true;
                    parentProcess.Exited += ParentProcessExitedHandler;
                }
            }
#endif

            AppDomain.CurrentDomain.UnhandledException += UnhandledExceptionHandler;

            ApplicationContext ctx = new ApplicationContext();
            activeHiddenForm = new HiddenForm();
            Application.Run(ctx);
        }

        static void UnhandledExceptionHandler(object sender, UnhandledExceptionEventArgs args)
        {
            Exception e = (Exception)args.ExceptionObject;
            activeHiddenForm.SendComMessage(ProcessComProtocol.MsgCode_SysError, e.Message);
            using (StreamWriter sw = File.AppendText("error-log.txt")) // UTF-8
            {
                sw.WriteLine(e.Message);
            }
        }

        static void ParentProcessExitedHandler(object sender, EventArgs e)
        {
            Exit();
        }

        public static void Exit()
        {
            // Exit for Message Loop app
            if (Application.MessageLoop)
                Application.Exit();

            // Exit for Console app
            else
                Environment.Exit(1);
        }
    }

    class HiddenForm : Form
    {
        const int comSocketPort = 9999;

        private Socket comClientListener;
        private Task ebayOrdersStoreCheckTask;

        private EbayApiMgr ebayApi;
        private EbayOrdersFileStore ebayOrdersStore;
        
        /// <summary>
        /// Constructor + init
        /// </summary>
        public HiddenForm()
        {
            Console.OutputEncoding = Encoding.UTF8;

            ebayApi = new EbayApiMgr(this);
            ebayApi.Init();

            ebayOrdersStore = new EbayOrdersFileStore(this, ebayApi);
            ebayOrdersStore.Init();

            IPHostEntry host = Dns.GetHostEntry("localhost");
            IPAddress ipAddress = host.AddressList[0];
            IPEndPoint localEndPoint = new IPEndPoint(ipAddress, comSocketPort);

            try
            {
                comClientListener = new Socket(ipAddress.AddressFamily, SocketType.Stream, ProtocolType.Tcp);

                comClientListener.Bind(localEndPoint);

                // How many requests a Socket can listen before it gives Server busy response.  
                comClientListener.Listen(1);

                object msgData = new { socketServerPort = comSocketPort };
                SendComMessage(ProcessComProtocol.MsgCode_ComSocketReady, msgData);
            }
            catch (Exception e)
            {
                SendComMessage(ProcessComProtocol.MsgCode_ComSocketError);
            }

            // Wait for client connected
            Task.Run(() =>
            {
                Socket comChannel = comClientListener.Accept();
                // *Client connected*
                comClientListener.Close();
                comClientListener = null;

                string sourceMsg = null;
                byte[] bytesBuffer = null;

                // Listen for messages from the client in a loop
                while (comChannel.Connected)
                {
                    // Reset buffers
                    sourceMsg = null;
                    bytesBuffer = null;

                    while (true)
                    {
                        //Console.Out.WriteLine("Entering receive loop");

                        bytesBuffer = new byte[1024];
                        int bytesRec = comChannel.Receive(bytesBuffer); // Block wait

                        // *Receive pass*

                        sourceMsg += Encoding.UTF8.GetString(bytesBuffer, 0, bytesRec);

                        if (sourceMsg.IndexOf(ProcessComProtocol.EndOfMessageSign) > -1)
                            break;
                    }

                    ProcessReceivedMessage(ParseComProtocolMessage(sourceMsg));
                }

                comChannel.Shutdown(SocketShutdown.Both);
                comChannel.Close();
                SendComMessage(ProcessComProtocol.MsgCode_ComSocketError);
            });

            #if DEBUG
            while (true)
            {
                ProcessReceivedMessage(new ProcessComProtocolMessage(QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheck, 3, null));
                Console.ReadLine();
                //ebayOrdersStore.ReloadFile();
                //ebayOrdersStoreCheckTask = Task.Run(ebayOrdersStoreCheckFunc);
                //ebayOrdersStoreCheckTask.Wait();
                ProcessReceivedMessage(new ProcessComProtocolMessage(QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheck, 3, null));

            }
#endif
        }

        private ProcessComProtocolMessage ParseComProtocolMessage(string rawSource)
        {
            // Remove 'end of message' sign in the end of the raw message
            rawSource = rawSource.Remove(rawSource.IndexOf(ProcessComProtocol.EndOfMessageSign));

            var msgComponents = rawSource.Split(ProcessComProtocol.DataSeparator);

            var msgCode = int.Parse(msgComponents[0]);
            var msgTypeCode = int.Parse(msgComponents[1]);
            object msgData = null;

            if (msgTypeCode != ProcessComProtocol.MsgType_Signal)
                msgData = msgComponents[2] as string;

            if (msgTypeCode == ProcessComProtocol.MsgType_JSON)
            {
                dynamic msgDataOb = JsonConvert.DeserializeObject(msgData as string);
                msgData = msgDataOb;
            }

            return new ProcessComProtocolMessage(msgCode, msgTypeCode, msgData);
        }

        public void SendComMessage(int msgCode)
        {
            SendComMessage(msgCode, ProcessComProtocol.MsgType_Signal);
        }

        public void SendComMessage(int msgCode, string dataPlainString)
        {
            SendComMessage(msgCode, ProcessComProtocol.MsgType_Plain, dataPlainString);
        }

        public void SendComMessage(int msgCode, object dataObject)
        {
            SendComMessage(msgCode, ProcessComProtocol.MsgType_JSON, dataObject);
        }

        private void SendComMessage(int msgCode, int msgType, object msgData = null)
        {
            string encodedMsg =
                msgCode.ToString() + ProcessComProtocol.DataSeparator +
                msgType.ToString() + ProcessComProtocol.DataSeparator;

            if (msgType == ProcessComProtocol.MsgType_Plain)
            {
                encodedMsg += msgData as string;
            }

            else

            if (msgType == ProcessComProtocol.MsgType_JSON)
            {
                encodedMsg += JsonConvert.SerializeObject(msgData);
            }

            encodedMsg += ProcessComProtocol.EndOfMessageSign;

            Console.Out.Write(encodedMsg);
        }

        private void ProcessReceivedMessage(ProcessComProtocolMessage msg)
        {
            if (msg.Code == QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheck || msg.Code == QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheckFull)
            {
                SendComMessage(ProcessComProtocol.MsgCode_PlainMessage, "Execute order pass");
                //if (ebayOrdersStoreCheckTask == null || 
                //    (ebayOrdersStoreCheckTask.Status != TaskStatus.Running && ebayOrdersStoreCheckTask.Status != TaskStatus.RanToCompletion))
                //{
                if (ebayOrdersStoreCheckTask == null || ebayOrdersStoreCheckTask.IsCompleted)
                {

                    SendComMessage(ProcessComProtocol.MsgCode_PlainMessage, "Task run condition pass");

                    ebayOrdersStoreCheckTask =
                        msg.Code == QnProcessComProtocol.MsgCode_ExecuteEbayOrdersCheck ?
                            Task.Run(EbayOrdersStoreCheck) : Task.Run(EbayOrdersStoreFullCheck);
                    ebayOrdersStoreCheckTask.ContinueWith(task => ebayOrdersStoreCheckTask = null);
                }
            }

            else

            if (msg.Code == QnProcessComProtocol.MsgCode_ClearEbayOrdersCache)
            {
                ebayOrdersStore.ClearCache();
            }

            else

            if (msg.Code == QnProcessComProtocol.MsgCode_CancelEbayOrdersCheck)
            {
                if (ebayOrdersStoreCheckTask != null || ebayOrdersStoreCheckTask.Status == TaskStatus.Running)
                {
                    //ebayOrdersStoreCheckTask.Cancel()
                }
            }
        }

        private async Task EbayOrdersStoreCheck() => await ebayOrdersStore.CheckAsync();
        private async Task EbayOrdersStoreFullCheck() => await ebayOrdersStore.CheckAsync(true);
    }
}
