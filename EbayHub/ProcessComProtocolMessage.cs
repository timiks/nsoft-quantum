using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    class ProcessComProtocolMessage
    {
        public int Code { get; }
        public int Type { get; }
        public object Data { get; }

        public ProcessComProtocolMessage(int code, int type, object data)
        {
            Code = code;
            Type = type;
            Data = data;
        }
    }
}
