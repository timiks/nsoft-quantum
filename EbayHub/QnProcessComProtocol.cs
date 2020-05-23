using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    class QnProcessComProtocol
    {
        public static int MsgCode_ExecuteEbayOrdersCheck = 0x64; // Signal
        public static int MsgCode_EbayOrdersCheckStarted = 0x65; // Signal
        public static int MsgCode_EbayOrdersCheckError = 0x66; // With data
        public static int MsgCode_EbayOrdersCheckSuccess = 0x67; // With data
        public static int MsgCode_EbayOrdersStoreUpdated = 0x68; // Signal
    }
}
