using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GizyitClient
{
    public class CmdDecEnc
    {
        public static byte[] EncodeBuffCfg(UInt32 msc, UInt32 mpsc)
        {
            byte[] ibuf = new byte[9];
            ibuf[0] = 4;
            //64bit Payload
            ibuf[1] = (byte)((msc & 0x000000FF) >> 0);
            ibuf[2] = (byte)((msc & 0x0000FF00) >> 8);
            ibuf[3] = (byte)((msc & 0x00FF0000) >> 16);
            ibuf[4] = (byte)((msc & 0xFF000000) >> 24);

            ibuf[5] = (byte)((mpsc & 0x000000FF) >> 0);
            ibuf[6] = (byte)((mpsc & 0x0000FF00) >> 8);
            ibuf[7] = (byte)((mpsc & 0x00FF0000) >> 16);
            ibuf[8] = (byte)((mpsc & 0xFF000000) >> 24);
            return ibuf;
        }

        public static byte[] EncodeTrigCfg(int dp, int ach, int dcch, int ech, int et, int ete, int pte)
        {
            //8bit command code
            byte[] ibuf = new byte[9];
            ibuf[0] = 3;
            //64bit Payload
            ibuf[1] = (byte)((dp & 0xFF00) >> 8);
            ibuf[2] = (byte)((dp & 0x00FF) >> 0);
            ibuf[3] = (byte)((ach & 0xFF00) >> 8);
            ibuf[4] = (byte)((ach & 0x00FF) >> 0);
            ibuf[5] = (byte)((dcch & 0xFF00) >> 8);
            ibuf[6] = (byte)((dcch & 0x00FF) >> 0);
            ibuf[7] = (byte)(ech);
            ibuf[8] = (byte)(((et & 0x1) << 2) + ((ete  & 0x1)<< 1) + ((pte & 0x1) << 0));
            return ibuf;
        }

        public static byte[] EncodeSimple(byte code)
        {
            //8bit command code
            byte[] ibuf = new byte[9];
            ibuf[0] = code;
            //64bit Payload
            ibuf[1] = (byte)0;
            ibuf[2] = (byte)0;
            ibuf[3] = (byte)0;
            ibuf[4] = (byte)0;
            ibuf[5] = (byte)0;
            ibuf[6] = (byte)0;
            ibuf[7] = (byte)0;
            ibuf[8] = (byte)0;
            return ibuf;
        }

        public static void DecodeTraceSize()
        {

        }

        public static void DecodeTriggerSample()
        {

        }

        public static void DecodeStatus()
        {

        }

        public static void DecodeCack()
        {

        }

        public static void DecodeTrigCfg()
        {

        }

        public static void DecodeBuffCfg()
        {

        }

        public static void DecodeTraceData()
        {

        }
    }
}
