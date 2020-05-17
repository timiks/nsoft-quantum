﻿using System;
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
        private static Process parentProcess;

        // Entry point
        [STAThread]
        static void Main(string[] args)
        {
            // Invalid launch protection
            if (args.Length < 1)
                Exit();

            if (args[0] != "run")
                Exit();

            if (args.Length == 2)
            {
                string parentProcessName = args[1];

                Process[] processQuery = Process.GetProcessesByName(parentProcessName);
                if (processQuery.Length == 0)
                    // No parent process found
                    Exit();

                foreach (Process prc in processQuery)
                {
                    if (prc.ProcessName == parentProcessName)
                    {
                        parentProcess = prc;
                        parentProcess.EnableRaisingEvents = true;
                        parentProcess.Exited += ParentProcessExitedHandler;
                        break;
                    }
                }
            }

            ApplicationContext ctx = new ApplicationContext();
            _ = new HiddenForm();
            Application.Run(ctx);
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
        private Socket comClientListener;
        
        public HiddenForm()
        {
            Console.OutputEncoding = Encoding.UTF8;

            //string tst = "1" + ProcessComProtocol.DataSeparator + "2" + ProcessComProtocol.DataSeparator + "{\"Hola\": \"Amigo\"}" + ProcessComProtocol.EndOfMessageSign;
            //ParseComProtocolMessage(tst);

            IPHostEntry host = Dns.GetHostEntry("localhost");
            IPAddress ipAddress = host.AddressList[0];
            IPEndPoint localEndPoint = new IPEndPoint(ipAddress, 9999);

            try
            {
                comClientListener = new Socket(ipAddress.AddressFamily, SocketType.Stream, ProtocolType.Tcp);

                comClientListener.Bind(localEndPoint);

                // How many requests a Socket can listen before it gives Server busy response.  
                comClientListener.Listen(1);

                object msgData = new { socketServerPort = 9999 };
                SendComMessage(ProcessComProtocol.MsgCode_ComSocketReady, msgData);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
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
                while (true)
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

                    //Console.Out.WriteLine("Echo: " + sourceMsg);
                }

                //comChannel.Shutdown(SocketShutdown.Both);
                //comChannel.Close();
            });
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

        private void SendComMessage(int msgCode)
        {
            SendComMessage(msgCode, ProcessComProtocol.MsgType_Signal);
        }

        private void SendComMessage(int msgCode, string dataPlainString)
        {
            SendComMessage(msgCode, ProcessComProtocol.MsgType_Plain, dataPlainString);
        }

        private void SendComMessage(int msgCode, object dataObject)
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
            SendComMessage(ProcessComProtocol.MsgCode_PlainMessage, "Got plain message!");
        }
    }
}
