using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace Quantum.ClipboardSvc
{
    static class Program
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
            Exit();
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
        [DllImport("User32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SetClipboardViewer(IntPtr hWndNewViewer);

        [DllImport("User32.dll", CharSet = CharSet.Auto)]
        public static extern bool ChangeClipboardChain(IntPtr hWndRemove, IntPtr hWndNewNext);

        const int WM_DRAWCLIPBOARD = 0x0308; // WM_DRAWCLIPBOARD Message

        private IntPtr clipboardViewerNext;

        public HiddenForm()
        {
            clipboardViewerNext = SetClipboardViewer(Handle);
            FormClosing += HiddenForm_FormClosing;
        }

        private void HiddenForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            ChangeClipboardChain(Handle, clipboardViewerNext);
        }

        protected override void WndProc(ref Message m)
        {
            base.WndProc(ref m); // Process the message 

            if (m.Msg == WM_DRAWCLIPBOARD)
            {
                Debug.WriteLine("Clipboard Changed!");
                IDataObject iData = Clipboard.GetDataObject(); // Clipboard's data

                if (iData.GetDataPresent(DataFormats.Text))
                {
                    // Send simple signal to stdout
                    Console.Out.Write("1"); // Clipboard Changed
                }
            }
        }
    }
}