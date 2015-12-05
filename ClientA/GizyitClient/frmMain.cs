using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO.Ports;
using System.IO;
using System.Windows.Forms.DataVisualization.Charting;

namespace GizyitClient
{
    public partial class frmMain : Form
    {
        //private System.Collections.Generic.List<char[]> middleBuffer = new System.Collections.Generic.List<char[]>();
        private System.Threading.Mutex mMutexRemote = new System.Threading.Mutex(false);
        private System.Threading.Mutex mMutexLocal = new System.Threading.Mutex(false);
        private System.Collections.Generic.Queue<char[]> remoteQ = new Queue<char[]>();
        private System.Collections.Generic.Queue<char[]> localQ = new Queue<char[]>();
        private System.Collections.ArrayList dataStore = new System.Collections.ArrayList();

        private string dataFileName = "test.dat";
        Chart[] charts = null;

        public frmMain()
        {
            InitializeComponent();

            charts = new Chart[16];
            charts[0] = chart1;
            charts[1] = chart2;
            charts[2] = chart3;
            charts[3] = chart4;
            charts[4] = chart5;
            charts[5] = chart6;
            charts[6] = chart7;
            charts[7] = chart8;
            charts[8] = chart9;
            charts[9] = chart10;
            charts[10] = chart11;
            charts[11] = chart12;
            charts[12] = chart13;
            charts[13] = chart14;
            charts[14] = chart15;
            charts[15] = chart16;
        }   

        private void frmMain_Load(object sender, EventArgs e)
        {

        }        

        private void btnConnect_Click(object sender, EventArgs e)
        {
            if (btnConnect.Text.StartsWith("Connect"))
            {
                serialPort.PortName = "COM" + txtCOMPortNumber.Text;
                serialPort.BaudRate = int.Parse(txtBaudrate.Text);
                serialPort.DataBits = 8;
                serialPort.Open();

                worker.RunWorkerAsync();

                groupBox2.Enabled = true;
                //timerStatus.Enabled = true;
                btnConnect.Text = "Disconnect";

            }
            else
            {
                //timerStatus.Enabled = false;
                groupBox2.Enabled = false;
                worker.CancelAsync();
                System.Threading.Thread.Sleep(1000);
                serialPort.Close();
                
                btnConnect.Text = "Connect";

            }
        }
        


        private void WriteSerialPort(SerialPort port, char[] dat)
        {
            port.Write(dat, 0, 4);            
        }

        private enum FunctionCode
        {
            START=0x1,
            ABORT=0x2,
            WRITE_TRIG_CFG = 0x3,
            WRITE_BUFF_CFG=0x4,            
            TRACE_DATA=0x5,
            TRACE_SIZE=0x6,
            TRIGGER_SAMPLE=0x7,
            BUFF_CFG=0xA,
            TRIG_CFG=0xB,
            CACK=0xDD,
            STATUS=0xEE,
            HEARTBEAT=0xFF
            
        }
        private enum FunctionSubCode
        {
            TRACEDATA=0
        }
        private void backgroundWorker1_DoWork(object sender, DoWorkEventArgs e)
        {
            int funCode=0;
            int payloadSize = 0;

            
            int state = 0;
            int totalToRead = 0;


            char[] chunk = null;

            int actualSizeRead = 0;
            totalToRead = 5;

            while (true)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }


                //
                //This state machine is complicated because:
                // Serial Port Reads cannot block; therefore they time out.
                // There is no way to know at which byte in which message will be the last byte.
                // So, the state machine carefully keeps track of where it is in message retrieval
                // so that in the event of a timeout,  it can continue trying at the same spot.
                // We do not want to block because than we have trouble closing the port.
                // We want to avoid hanging the port across many many debug tries.
                //
                // This client communicates with the Logic Analyzer using a binary format.
                // As a result, .NET forces us to read from the serial port 1 byte at a time.
                // Maybe there is an alternative to this. DYOR.

                switch (state)
                {
                    case 0://Initialize stuff
                        serialPort.ReadTimeout = 500;
                        actualSizeRead = 0;
                        totalToRead = 5;
                        chunk = new char[totalToRead];
                        state = 1;                        
                        break;
                    case 1://Read message header (if there is one)
                        
                        try
                        {
                            while (actualSizeRead < totalToRead)
                            {
                                //int s = serialPort.Read(chunk, actualSizeRead, totalToRead - actualSizeRead);
                                int s = serialPort.ReadByte();
                                chunk[actualSizeRead] = (char)s;
                                actualSizeRead += 1;
                            }                    
                        }
                        catch (TimeoutException toe)
                        {
                            state = 1;
                            break;
                        }

                        //We made it past state 1 - we have header
                        funCode = (int)(chunk[0]);

                        payloadSize = (((int)(chunk[4]) << 24) | ((int)(chunk[3]) << 16) | ((int)(chunk[2]) << 8) | ((int)(chunk[1]) << 0));

                        actualSizeRead = 0;
                        totalToRead = payloadSize;
                        chunk = null;
                        chunk = new char[totalToRead];
                        if (funCode == (int)FunctionCode.TRACE_DATA)
                        {
                            dataStore.Clear();
                        }
                        state = 2;
                        
                       
                        break;
                    case 2:
                        try
                        {
                            while (actualSizeRead < totalToRead)
                            {
                             
                                int s = serialPort.ReadByte();
                                chunk[actualSizeRead] = (char)s;
                                if (funCode == (int)FunctionCode.TRACE_DATA)
                                {
                                    dataStore.Add((byte)s);
                                }

                                actualSizeRead += 1;                               
                            }
                        }
                        catch (TimeoutException toe)
                        {
                            state = 2;
                            break;
                        }
                        //we made it past state 2 - we have payload
                        state = 3;
                        break;
                    case 3:
                        // In this State, we have finished downloading the payload.
                        // So we can notify of the completion of different items here.

                        //Direct payload to it's destination.
                        byte[] rawChunk = new byte[chunk.Length];

                        for (int i = 0; i < chunk.Length; i++)
                        {
                            rawChunk[i] = (byte)chunk[i];
                        }

                        FinishProcessing(funCode, rawChunk);

                        //we made it past state 3- we did stuff with data, going back to state 0
                        state = 0;
                        break;
                    default:
                        break;
                }
                
                worker.ReportProgress(100);
                System.Threading.Thread.Sleep(10);
            }
        }

        private void FinishProcessing(int funCode, byte[] rawChunk)
        {
            switch ((FunctionCode)funCode)
            {
                case FunctionCode.TRACE_DATA:
                    EnqueueRemoteChunk("Finished Downloading Data\r\n".ToCharArray());
                    break;
                case FunctionCode.TRIGGER_SAMPLE:
                    {

                        string msg = String.Format("Trigger Sample: {0} sample number",
                             (rawChunk[3] << (byte)24) + (rawChunk[2] << (byte)16) + (rawChunk[1] << (byte)8) + rawChunk[0]);

                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        break;
                    }
                case FunctionCode.TRACE_SIZE:
                    {

                        string msg = String.Format("TraceSize: {0} bytes",
                             (rawChunk[3] << (byte)24) + (rawChunk[2] << (byte)16) + (rawChunk[1] << (byte)8) + rawChunk[0]);

                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        break;
                    }
                case FunctionCode.TRIG_CFG:
                    {
                        string msg = String.Format("Trig Cfg:\r\n Desired=0x{0:X4}\r\n Active=0x{1:X4}\r\n DontCare=0x{2:X4}\r\n EdgeChannel=0x{3:X2}\r\n Bits=0x{4:X2}",
                                                    (rawChunk[1] << (byte)8) + rawChunk[0],
                                                    (rawChunk[3] << (byte)8) + rawChunk[2],
                                                    (rawChunk[5] << (byte)8) + rawChunk[4],
                                                    (byte)rawChunk[6],
                                                    (byte)rawChunk[7]);
                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        break;
                    }
                case FunctionCode.BUFF_CFG:
                    {
                        string msg = String.Format("Buff Cfg:\r\n MaxSampleCount=0x{0:X4}\r\n MaxPreTrigSampleCount=0x{1:X4}",
                                                    (rawChunk[3] << (byte)24) + (rawChunk[2] << (byte)16) + (rawChunk[1] << (byte)8) + rawChunk[0],
                                                    (rawChunk[7] << (byte)24) + (rawChunk[6] << (byte)16) + (rawChunk[5] << (byte)8) + rawChunk[4]);
                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        break;
                    }
                case FunctionCode.CACK:
                    {
                        string cackOrigin = String.Empty;                       
                        switch ((FunctionCode)rawChunk[0])
                        {
                            case FunctionCode.TRACE_DATA:
                                cackOrigin = "Read Trace Data";
                                break;
                            case FunctionCode.TRACE_SIZE:
                                cackOrigin = "Read Trace Size";
                                break;
                            case FunctionCode.TRIGGER_SAMPLE:
                                cackOrigin = "Read Trigger Sample";
                                break;
                            case FunctionCode.BUFF_CFG:
                                cackOrigin = "Read Buff Cfg";
                                break;
                            case FunctionCode.TRIG_CFG:
                                cackOrigin = "Read Trig Cfg";
                                break;
                            case FunctionCode.STATUS:
                                cackOrigin = "Read Status";
                                break;
                            case FunctionCode.START:
                                cackOrigin = "Start";
                                break;
                            case FunctionCode.ABORT:
                                cackOrigin = "Abort";
                                break;
                            case FunctionCode.WRITE_BUFF_CFG:
                                cackOrigin = "Set Buff Cfg";
                                break;
                            case FunctionCode.WRITE_TRIG_CFG:
                                cackOrigin = "Set Trig Cfg";
                                break;
                            default:
                                break;
                        }
                        string msg = String.Format("{0} Ack'd", cackOrigin);

                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        
                        break;
                    }
                case FunctionCode.HEARTBEAT:
                    EnqueueRemoteChunk("HeartBeat: Rx'd\r\n".ToCharArray());
                    break;
                case FunctionCode.STATUS:
                    {
                        string msg = String.Format("Idle:{0}  Pre:{1}  Post:{2}", (rawChunk[0] & 0x01) == 1 ? "Yes" : "No",
                                                                                  (rawChunk[0] & 0x02) == 1 ? "Yes" : "No",
                                                                                  (rawChunk[0] & 0x04) == 1 ? "Yes" : "No");
                        EnqueueRemoteChunk((msg + "\r\n").ToCharArray());
                        break;
                    }
            }
        }

        private void EnqueueRemoteChunk(char[] chunk)
        {
            mMutexRemote.WaitOne();
            remoteQ.Enqueue(chunk);
            mMutexRemote.ReleaseMutex();
        }

        private String HexToText(byte[] hex)
        {
            String text = string.Empty;

            foreach (byte b in hex)
            {
                text += NibbleToHexString((char)(b >> (byte)4));
                text += NibbleToHexString((char)b) + " ";
            }
            return text;
        }


        //
        //This function runs in the context of the main UI thread.
        //This is how UI is updated by the background thread.
        //
        private void backgroundWorker1_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            bool updatePlot = false;
            
            mMutexRemote.WaitOne();
            while (remoteQ.Count > 0)
                {
                    bool supressText = false;        
                    char[] buff = remoteQ.Dequeue();

                    String addition = new String(buff);//HexToText(buff);
                    if (addition.Contains("Finished Downloading"))
                    {
                        updatePlot = true;
                    }
                    //if (addition.Contains("Idle:Yes"))
                    //{
                    //    pbIdleGood.Visible = true;
                    //    pbIdleBad.Visible = false;
                    //    supressText = true;
                    //}
                    //else if (addition.Contains("Idle:No"))
                    //{
                    //    pbIdleGood.Visible = false;
                    //    pbIdleBad.Visible = true;
                    //    supressText = true;
                    //}

                    if (addition.Contains("Read Status"))
                    {
                        supressText = true;
                    }

                    if (!supressText)
                    {
                        txtRemote.Text += addition;
                        txtRemote.SelectAll();
                        txtRemote.ScrollToCaret();
                    }
                }
            mMutexRemote.ReleaseMutex();

            //Update plot if we just downloaded
            // a new trace 
            if (updatePlot)
            {
                PlotDataStore();                
            }
        }

        //
        //This plots the data in the dataStore variable.
        // the dataStore variable holds all the samples that are  downloaded from the Logic Analyzer
        //
        private void PlotDataStore()
        {
            //Initialize the charts
            int ch = 0;
            foreach (Chart chart in charts)
            {
                string seriesName = String.Format("Ch{0}", ch);
                ch++;

                chart.Series.Clear();
                chart.Series.Add(seriesName);
                chart.Series[seriesName].ChartType = SeriesChartType.Line; 
                chart.ChartAreas["ChartArea1"].CursorX.IsUserEnabled = true;
                chart.ChartAreas["ChartArea1"].CursorX.IsUserSelectionEnabled = true;
                chart.ChartAreas["ChartArea1"].AxisY.Minimum = 0;
                chart.ChartAreas["ChartArea1"].AxisY.Maximum = 1;
                chart.ChartAreas["ChartArea1"].AxisY.Interval = 1;
            }



            //Create charts from raw data.
            //
            //For each sample, we plot a "shadow" sample right above it, or right below it
            //in order to achieve the square wave look in the plot.
            //If we didn't do this, and just plotted the raw samples by themselves, then
            //the signals would look more like a triangle wave.
            //
            byte rawByte0, rawByte1, rawByte2, rawByte3;
            
            byte[] last = new byte[16];
            byte[] cur = new byte[16];

            rawByte0 = (byte)dataStore[0];
            rawByte1 = (byte)dataStore[1];
            rawByte2 = (byte)dataStore[2];//ovrflw
            rawByte3 = (byte)dataStore[3];//ovrflw

            for (int j = 4; j < dataStore.Count; j+=4)
            {                
                last[0] = (byte)((rawByte0 & 0x1)   >> 0);
                last[1] = (byte)((rawByte0 & 0x2)   >> 1);
                last[2] = (byte)((rawByte0 & 0x4)   >> 2);
                last[3] = (byte)((rawByte0 & 0x8)   >> 3);
                last[4] = (byte)((rawByte0 & 0x10)  >> 4);
                last[5] = (byte)((rawByte0 & 0x20)  >> 5);
                last[6] = (byte)((rawByte0 & 0x40)  >> 6);
                last[7] = (byte)((rawByte0 & 0x80)  >> 7);
                last[8] = (byte)((rawByte1 & 0x1)   >> 0);
                last[9] = (byte)((rawByte1 & 0x2)   >> 1);
                last[10] = (byte)((rawByte1 & 0x4)  >> 2);
                last[11] = (byte)((rawByte1 & 0x8)  >> 3);
                last[12] = (byte)((rawByte1 & 0x10) >> 4);
                last[13] = (byte)((rawByte1 & 0x20) >> 5);
                last[14] = (byte)((rawByte1 & 0x40) >> 6);
                last[15] = (byte)((rawByte1 & 0x80) >> 7);

                rawByte0 = (byte)dataStore[j + 0];
                rawByte1 = (byte)dataStore[j + 1];
                rawByte2 = (byte)dataStore[j + 2];//ovrflw. We don't do anything with it currently. 
                rawByte3 = (byte)dataStore[j + 3];//ovrflw

                cur[0] = (byte)((rawByte0 & 0x1)    >> 0);
                cur[1] = (byte)((rawByte0 & 0x2)    >> 1);
                cur[2] = (byte)((rawByte0 & 0x4)    >> 2);
                cur[3] = (byte)((rawByte0 & 0x8)    >> 3);
                cur[4] = (byte)((rawByte0 & 0x10)   >> 4);
                cur[5] = (byte)((rawByte0 & 0x20)   >> 5);
                cur[6] = (byte)((rawByte0 & 0x40)   >> 6);
                cur[7] = (byte)((rawByte0 & 0x80)   >> 7);
                cur[8] = (byte)((rawByte1 & 0x1)    >> 0);
                cur[9] = (byte)((rawByte1 & 0x2)    >> 1);
                cur[10] = (byte)((rawByte1 & 0x4)   >> 2);
                cur[11] = (byte)((rawByte1 & 0x8)   >> 3);
                cur[12] = (byte)((rawByte1 & 0x10)  >> 4);
                cur[13] = (byte)((rawByte1 & 0x20)  >> 5);
                cur[14] = (byte)((rawByte1 & 0x40)  >> 6);
                cur[15] = (byte)((rawByte1 & 0x80)  >> 7);

                ch = 0;
                foreach (Chart chart in charts)
                {
                    if (cur[ch] != last[ch])
                    {
                        chart.Series[String.Format("Ch{0}", ch)].Points.AddXY(j / 4, last[ch]);
                    }
                    chart.Series[String.Format("Ch{0}", ch)].Points.AddXY(j / 4, cur[ch]);
                    ch++;
                }
            }
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            txtRemote.Clear();
        }

        private void saveDataFileToolStripMenuItem_Click(object sender, EventArgs e)
        {
            SaveFileDialog sfd = new SaveFileDialog();
            sfd.Title = "Save Data File as?";
            DialogResult dr = sfd.ShowDialog();
            if (dr == System.Windows.Forms.DialogResult.OK)
            {
                dataFileName = sfd.FileName;
            }
        }

        private void frmMain_FormClosed(object sender, FormClosedEventArgs e)
        {
            worker.CancelAsync();
            System.Threading.Thread.Sleep(1000);
            if (serialPort.IsOpen)
                serialPort.Close();
        }

        //
        // THe following chart event handlers are a work in progress.
        // To get the charts to behave as you'd like takes a lot of messing
        // around.  So i've left the commentted out code for my future benefit.
        //
        private void chart1_AxisViewChanging(object sender, ViewEventArgs e)
        {
            foreach (Chart chart in charts)
            {
                chart.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
                chart.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            }

        //    chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
        //    chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
   
        }

        
        private void chart1_AxisViewChanged(object sender, ViewEventArgs e)
        {
            //chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            //chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
        }
        private void chart1_SelectionRangeChanged(object sender, CursorEventArgs e)
        {
            
            //chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
        
            
        }             

        private void chart1_SelectionRangeChanging(object sender, CursorEventArgs e)
        {
            ////chart1.ChartAreas["ChartArea1"].CursorX.SelectionEnd
            //chart1.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart; 
            //chart4.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
        }

        private void chart1_CursorPositionChanging(object sender, CursorEventArgs e)
        {
            foreach (Chart chart in charts)
            {
                chart.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            }

            //chart1.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            //chart4.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart4.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
        }

        private void chart1_CursorPositionChanged(object sender, CursorEventArgs e)
        {

        }


        //
        //Save Trace
        //
        private void saveTraceAsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            SaveFileDialog sfd = new SaveFileDialog();
            sfd.Filter = "Trace Data (.dat)|*.dat";
            DialogResult dr = sfd.ShowDialog();
            if (dr == System.Windows.Forms.DialogResult.OK)
            {
                BinaryWriter bwriter = new BinaryWriter(File.Open(sfd.FileName, FileMode.Create));
                foreach (byte b in dataStore)
                {
                    bwriter.Write(b);
                }
                bwriter.Close();
            }
        }

        //
        //Load Trace
        //
        private void loadTraceToolStripMenuItem_Click(object sender, EventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "Trace Data (.dat)|*.dat";
            DialogResult dr = ofd.ShowDialog();
            if (dr == System.Windows.Forms.DialogResult.OK)
            {
                BinaryReader breader = new BinaryReader(File.Open(ofd.FileName, FileMode.Open));
                dataStore.Clear();
                for (int i = 0; i < breader.BaseStream.Length;i++ )
                {
                    dataStore.Add(breader.ReadByte());
                }
                breader.Close();
                PlotDataStore();
            }
        }

        private void btnSetBuffCfg_Click(object sender, EventArgs e)
        {
            //Send Write Buffer Config
            UInt32 msc = UInt32.Parse(txtMaxSampleCount.Text);
            UInt32 mpsc = UInt32.Parse(txtMaxPreTriggerSampleCount.Text);

            byte[] ibuf = CmdDecEnc.EncodeBuffCfg(msc, mpsc);
            serialPort.Write(ibuf, 0, 9);
        }



        private void btnSetTrigCfg_Click(object sender, EventArgs e)
        {            
            //Send Write Trigger Config
            int dp = (dp7.Checked  ? (1 << 7)  : 0) +
                     (dp6.Checked  ? (1 << 6)  : 0) +
                     (dp5.Checked  ? (1 << 5)  : 0) +
                     (dp4.Checked  ? (1 << 4)  : 0) +
                     (dp3.Checked  ? (1 << 3)  : 0) +
                     (dp2.Checked  ? (1 << 2)  : 0) +
                     (dp1.Checked  ? (1 << 1)  : 0) +
                     (dp0.Checked  ? (1 << 0)  : 0) +
                     (dp15.Checked ? (1 << 15) : 0) +
                     (dp14.Checked ? (1 << 14) : 0) +
                     (dp13.Checked ? (1 << 13) : 0) +
                     (dp12.Checked ? (1 << 12) : 0) +
                     (dp11.Checked ? (1 << 11) : 0) +
                     (dp10.Checked ? (1 << 10) : 0) +
                     (dp9.Checked  ? (1 << 9)  : 0) +
                     (dp8.Checked  ? (1 << 8)  : 0) ;

            int ac = (ac7.Checked ? (1 << 7) : 0) +
                     (ac6.Checked ? (1 << 6) : 0) +
                     (ac5.Checked ? (1 << 5) : 0) +
                     (ac4.Checked ? (1 << 4) : 0) +
                     (ac3.Checked ? (1 << 3) : 0) +
                     (ac2.Checked ? (1 << 2) : 0) +
                     (ac1.Checked ? (1 << 1) : 0) +
                     (ac0.Checked ? (1 << 0) : 0) +
                     (ac15.Checked ? (1 << 15) : 0) +
                     (ac14.Checked ? (1 << 14) : 0) +
                     (ac13.Checked ? (1 << 13) : 0) +
                     (ac12.Checked ? (1 << 12) : 0) +
                     (ac11.Checked ? (1 << 11) : 0) +
                     (ac10.Checked ? (1 << 10) : 0) +
                     (ac9.Checked ? (1 << 9) : 0) +
                     (ac8.Checked ? (1 << 8) : 0);
            int dc = (dc7.Checked ? (1 << 7) : 0) +
                     (dc6.Checked ? (1 << 6) : 0) +
                     (dc5.Checked ? (1 << 5) : 0) +
                     (dc4.Checked ? (1 << 4) : 0) +
                     (dc3.Checked ? (1 << 3) : 0) +
                     (dc2.Checked ? (1 << 2) : 0) +
                     (dc1.Checked ? (1 << 1) : 0) +
                     (dc0.Checked ? (1 << 0) : 0) +
                     (dc15.Checked ? (1 << 15) : 0) +
                     (dc14.Checked ? (1 << 14) : 0) +
                     (dc13.Checked ? (1 << 13) : 0) +
                     (dc12.Checked ? (1 << 12) : 0) +
                     (dc11.Checked ? (1 << 11) : 0) +
                     (dc10.Checked ? (1 << 10) : 0) +
                     (dc9.Checked ? (1 << 9) : 0) +
                     (dc8.Checked ? (1 << 8) : 0);

            int ech = Int32.Parse(txtEdgeChannel.Text)         & 0xff;
            int et = chbxEdgeType.Checked == true ? 1 : 0;
            int ete = chbxEdgeTriggerEnable.Checked == true ? 1 : 0;
            int pte = chbxPatternTriggerEnable.Checked == true ? 1 : 0;
            
            byte[] ibuf = CmdDecEnc.EncodeTrigCfg(dp, ac, dc,ech, et, ete, pte);
            
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnBegin_Click(object sender, EventArgs e)
        {
            btnSetBuffCfg_Click(null, null);
            btnSetTrigCfg_Click(null, null);
            btnSetStart_Click(null, null);
        }

        private void btnEnd_Click(object sender, EventArgs e)
        {
            btnSetAbort_Click(null, null);
            //TODO: Wait for Idle Status
            btnGetTrace_Click(null, null);
        }

        private void btnGetTrace_Click(object sender, EventArgs e)
        {            
            //Send Read Trace Data
            byte code = 0x05;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnGetStatus_Click(object sender, EventArgs e)
        {
            //Send Read Status
            byte code = 0xEE;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnGetTriggerSample_Click(object sender, EventArgs e)
        {
            //Send Read Trigger Sample Number
            byte code = 0x07;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnGetTraceSize_Click(object sender, EventArgs e)
        {
            //Send Read Trace Data Size
            byte code = 0x06;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnResetHW_Click(object sender, EventArgs e)
        {

        }

        private void btnGetTrigCfg_Click(object sender, EventArgs e)
        {
            //Send Read Trace Data Size
            byte code = 0x0B;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnGetBuffCfg_Click(object sender, EventArgs e)
        {
            //Send Read Trace Data Size
            byte code = 0x0A;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }


        private void btnSetCursor_Click(object sender, EventArgs e)
        {
            byte byte0, byte1;
            int ch=0;
            int sampleNum = int.Parse(txtCursorVal.Text);
            foreach (Chart chart in charts)
            {
                chart.ChartAreas["ChartArea1"].CursorX.Position = Convert.ToDouble(sampleNum);
                ch++;
            }

            //CConvert sample number to bytes.
            // This data has 4 byte samples. first two bytes are signals
            //  and the last two bytes are the overflow counter value (cycles since last sample) (not used so far)
            byte[] rawByte = new byte[2];            
            rawByte[0] = (byte)dataStore[((sampleNum ) * 4)+1];
            rawByte[1] = (byte)dataStore[((sampleNum ) * 4)+0];
            txtSelectedSample.Text = HexToText(rawByte);

            rawByte[0] = (byte)dataStore[((sampleNum) * 4) + 3];
            rawByte[1] = (byte)dataStore[((sampleNum) * 4) + 2];
            lblOverflow.Text = HexToText(rawByte);
        }

        private static string NibbleToHexString(char ch)
        {
            switch ((byte)ch & 0x0f)
            {
                case 0: return "0";
                case 1: return "1";
                case 2: return "2";
                case 3: return "3";
                case 4: return "4";
                case 5: return "5";
                case 6: return "6";
                case 7: return "7";
                case 8: return "8";
                case 9: return "9";
                case 10: return "A";
                case 11: return "B";
                case 12: return "C";
                case 13: return "D";
                case 14: return "E";
                case 15: return "F";
                default: return "X";
            }
        }



        private void tableLayoutPanel1_Paint(object sender, PaintEventArgs e)
        {

        }

        private void btnSetStart_Click(object sender, EventArgs e)
        {
            byte code = 0x01;
            //Send Start
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void btnSetAbort_Click(object sender, EventArgs e)
        {
            //Send Abort
            byte code = 0x02;
            byte[] ibuf = CmdDecEnc.EncodeSimple(code);
            serialPort.Write(ibuf, 0, 9);
        }

        private void timerStatus_Tick(object sender, EventArgs e)
        {
            btnGetStatus_Click(null, null);
        }
    }
}
