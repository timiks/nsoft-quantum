using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    class ProcessComProtocol
    {
		public static char DataSeparator = '\u001E';
		public static char EndOfMessageSign = '\u0004';
		
		public static byte MsgType_Plain = 0x1;
		public static byte MsgType_JSON = 0x2;
		public static byte MsgType_Signal = 0x3;
		
		public static int MsgCode_ComSocketReady = 0x1;
		public static int MsgCode_ComSocketError = 0x2;
		public static int MsgCode_PlainMessage = 0x3;
    }
}
