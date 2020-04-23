using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace AddressyService
{
    static class Program
    {
        // Entry point
        [STAThread]
        static void Main(string[] args)
        {
            string parentProcessNameArg = "Addressy";
            Debug.WriteLine("Args Length: " + args.Length);
            if (args.Length < 1)
            {
                exitProcess();
            }
            else
            {
                if (args[0] != "/run")
                {
                    exitProcess();
                }
                else if (args.Length == 2)
                {
                    parentProcessNameArg = args[1];
                }
            }

            Debug.WriteLine("Args:");
            foreach (string arg in args)
            {
                Debug.WriteLine("+ " + arg);
            }

            ApplicationContext ctx = new ApplicationContext();
            Form frmHidden = new HiddenForm(ctx, parentProcessNameArg);
            Application.Run(ctx);
        }

        public static void exitProcess()
        {
            if (Application.MessageLoop)
            {
                // Exit for WinForms app
                Application.Exit();
            }
            else
            {
                // Exit for Console app
                Environment.Exit(1);
            }
        }
    }

    internal class HiddenForm : Form
    {
        [DllImport("User32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr SetClipboardViewer(IntPtr hWndNewViewer);

        [DllImport("User32.dll", CharSet = CharSet.Auto)]
        public static extern bool ChangeClipboardChain(IntPtr hWndRemove, IntPtr hWndNewNext);

        private const int WM_DRAWCLIPBOARD = 0x0308; // WM_DRAWCLIPBOARD Message
        private IntPtr clipboardViewerNext;

        private ApplicationContext ctx;
        private Process parentProcess;
        private string parentProcessName;

        public HiddenForm(ApplicationContext context, string parentPrcName)
        {
            ctx = context;
            parentProcessName = parentPrcName;

            clipboardViewerNext = SetClipboardViewer(this.Handle);
            FormClosing += HiddenForm_FormClosing;

            Process[] prcs = Process.GetProcessesByName(parentProcessName);
            if (prcs.Length == 0)
            {
                Debug.WriteLine("No Parent Process Found");
                Program.exitProcess();
            }

            foreach (Process prc in prcs)
            {
                Debug.WriteLine("Parent Process: " + prc.Id + " " + prc.ProcessName);
                if (prc.ProcessName == parentProcessName)
                {
                    parentProcess = prc;
                    parentProcess.EnableRaisingEvents = true;
                    parentProcess.Exited += ParentProcess_Exited;
                    break;
                }
            }
        }

        private void ParentProcess_Exited(object sender, EventArgs e)
        {
            Debug.WriteLine("Parent Process has EXITED. Terminating...");
            Debug.WriteLine("Sender Type: " + sender.GetType().FullName);
            Program.exitProcess();
        }

        private void HiddenForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            ChangeClipboardChain(this.Handle, clipboardViewerNext);
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
                    // Write to Output
                    TextWriter stdout = Console.Out;
                    stdout.Write("1"); // Clipboard Changed
                }
            }
        }
    }
}
