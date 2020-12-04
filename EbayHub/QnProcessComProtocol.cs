using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    class QnProcessComProtocol
    {
        public static int MsgCode_ExecuteEbayOrdersCheck        = 100; // Signal
        public static int MsgCode_EbayOrdersCheckStarted        = 101; // Signal
        public static int MsgCode_EbayOrdersCheckError          = 102; // +Data
        public static int MsgCode_EbayOrdersCheckSuccess        = 103; // +Data
        public static int MsgCode_EbayOrdersStoreUpdated        = 104; // Signal
        public static int MsgCode_EbayAuthTokenError            = 105; // Signal
        public static int MsgCode_EbayAuthTokenExpiryWarning    = 106; // +Data (plain)
        public static int MsgCode_ClearEbayOrdersCache          = 107; // +Signal
        public static int MsgCode_ExecuteEbayOrdersCheckFull    = 108; // +Signal
        public static int MsgCode_CancelEbayOrdersCheck         = 109; // +Signal
        public static int MsgCode_EbayOrdersCacheCleared        = 110; // +Signal
    }
}
