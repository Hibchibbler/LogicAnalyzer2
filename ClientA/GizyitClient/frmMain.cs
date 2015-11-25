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

        public frmMain()
        {
            InitializeComponent();
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
                btnConnect.Text = "Disconnect";
                btnSend.Enabled = true;
            }
            else
            {
                worker.CancelAsync();
                System.Threading.Thread.Sleep(1000);
                serialPort.Close();
                btnConnect.Text = "Connect";
                btnSend.Enabled = false;
            }
        }
        


        private void WriteSerialPort(SerialPort port, char[] dat)
        {
            port.Write(dat, 0, 4);            
        }

        private enum FunctionCode
        {
            TEXT,
            DATA,
            ERROR,                        
            DEBUG,
            CMDACK
        }
        private enum FunctionSubCode
        {
            TRACEDATA=0
        }
        private void backgroundWorker1_DoWork(object sender, DoWorkEventArgs e)
        {
            int pc = 0;
            int funCode=0;
            int funSubCode=0;
            int payloadSize = 0;
            int completionState = 0;
            int ret = 0;
            
            int state = 0;
            int totalToRead = 0;


            char[] chunk = null;// new char[6];
            byte[] chunk2 = null;
            int actualSizeRead = 0;
            totalToRead = 6;

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
                        totalToRead = 6;
                        chunk = new char[6];
                        state = 1;                        
                        break;
                    case 1://Read message header (if there is one)
                        
                        try
                        {
                            while (actualSizeRead < totalToRead)
                            {
                                int s = serialPort.Read(chunk, actualSizeRead, totalToRead - actualSizeRead);
                                actualSizeRead += s;
                            }                    
                        }
                        catch (TimeoutException toe)
                        {
                            state = 1;
                            break;
                        }

                        //We made it past state 1 - we have header
                        funCode = (int)(chunk[0]);
                        funSubCode = (int)(chunk[1]);
                        payloadSize = (((int)(chunk[2]) << 24) | ((int)(chunk[3]) << 16) | ((int)(chunk[4]) << 8) | ((int)(chunk[5]) << 0));

                        actualSizeRead = 0;
                        totalToRead = payloadSize;
                        chunk = new char[totalToRead];
                        chunk2 = new byte[totalToRead];

                        
                        if (funCode == 1 && funSubCode == 0)
                        {//We are downloading a trace, so prepare the dataStore
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

                                //If trace data payload; put it directly into the data store.
                                if (funCode == 1 && funSubCode == 0)
                                {
                                    dataStore.Add((byte)s);
                                }
                                actualSizeRead += 1;
                            }
                        }
                        catch (TimeoutException toe)
                        {
                            state = 2;

                            mMutexRemote.WaitOne();
                             remoteQ.Enqueue(".... ".ToCharArray());
                            mMutexRemote.ReleaseMutex();
                            break;
                        }

                        //we made it past state 2 - we have payload
                        state = 3;

                        

                        break;
                    case 3:
                        //Direct payload to it's destination.
                        byte[] rawChunk = new byte[chunk.Count()];

                        switch ((FunctionCode)funCode)
                        {
                            case FunctionCode.TEXT:
                                mMutexRemote.WaitOne();
                                remoteQ.Enqueue(chunk);
                            mMutexRemote.ReleaseMutex();
                                break;
                            case FunctionCode.DATA:
                                switch ((FunctionSubCode)funSubCode)
                                {
                                    case FunctionSubCode.TRACEDATA:
                                        {
                                            mMutexLocal.WaitOne();
                                            localQ.Enqueue("Finished Downloading\r\n".ToCharArray());
                                            mMutexLocal.ReleaseMutex();
                                            break;
                                        }
                                    default:
                                        break;
                                }
                                break;
                            case FunctionCode.ERROR:
                                mMutexRemote.WaitOne();
                                remoteQ.Enqueue(chunk);
                            mMutexRemote.ReleaseMutex();
                                break;
                            case FunctionCode.DEBUG:
                               mMutexRemote.WaitOne();
                               remoteQ.Enqueue(chunk);
                            mMutexRemote.ReleaseMutex();
                                break;
                            case FunctionCode.CMDACK:

                                break;
                        }

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
                    char[] buff = remoteQ.Dequeue();
                                
                    String addition = new String(buff);
          
                    txtRemote.Text += addition;
                    txtRemote.SelectAll();
                    txtRemote.ScrollToCaret();               
                }
            mMutexRemote.ReleaseMutex();

            mMutexLocal.WaitOne();
            while (localQ.Count > 0)
            {
                char[] buff = localQ.Dequeue();

                String addition = new String(buff);
                if (addition.Contains("Finished Downloading"))
                    updatePlot = true;
                txtLocal.Text += addition;
                txtLocal.SelectAll();
                txtLocal.ScrollToCaret();
            }
            mMutexLocal.ReleaseMutex();


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
            //Initialize the 4 line charts.
            //
            //N.B. - the spaces in the names SO and SI are necessary to keep the charts aligned.
            chart1.Series.Clear();
            chart1.Series.Add("CSn");
            chart1.Series["CSn"].ChartType = SeriesChartType.FastLine;
            chart1.ChartAreas["ChartArea1"].CursorX.IsUserEnabled = true;
            chart1.ChartAreas["ChartArea1"].CursorX.IsUserSelectionEnabled = true;

            chart2.Series.Clear();
            chart2.Series.Add("SO ");
            chart2.Series["SO "].ChartType = SeriesChartType.FastLine;
            chart2.ChartAreas["ChartArea1"].CursorX.IsUserEnabled = true;
            chart2.ChartAreas["ChartArea1"].CursorX.IsUserSelectionEnabled = true;

            chart3.Series.Clear();
            chart3.Series.Add("SI ");
            chart3.Series["SI "].ChartType = SeriesChartType.FastLine;
            chart3.ChartAreas["ChartArea1"].CursorX.IsUserEnabled = true;
            chart3.ChartAreas["ChartArea1"].CursorX.IsUserSelectionEnabled = true;

            chart4.Series.Clear();
            chart4.Series.Add("SCK");
            chart4.Series["SCK"].ChartType = SeriesChartType.FastLine;
            chart4.ChartAreas["ChartArea1"].CursorX.IsUserEnabled = true;
            chart4.ChartAreas["ChartArea1"].CursorX.IsUserSelectionEnabled = true;


            //Create charts from raw data.
            //
            //For each sample, we plot a "shadow" sample right above it, or right below it
            //in order to achieve the square wave look in the plot.
            //If we didn't do this, and just plotted the raw samples by themselves, then
            //the signals would look more like a triangle wave.
            //
            byte rawByte;
            byte last0 = 0, last1 = 0, last2 = 0, last3 = 0;
            byte cur0 = 0, cur1 = 0, cur2 = 0, cur3 = 0;

            rawByte = (byte)dataStore[0];
            for (int j = 1; j < dataStore.Count; j++)
            {
                last0 = (byte)((rawByte & 0x1) >> 0);
                last1 = (byte)((rawByte & 0x2) >> 1);
                last2 = (byte)((rawByte & 0x4) >> 2);
                last3 = (byte)((rawByte & 0x8) >> 3);
                rawByte = (byte)dataStore[j];
                cur0 = (byte)((rawByte & 0x1) >> 0);
                cur1 = (byte)((rawByte & 0x2) >> 1);
                cur2 = (byte)((rawByte & 0x4) >> 2);
                cur3 = (byte)((rawByte & 0x8) >> 3);

                if (cur0 != last0)
                {
                    chart1.Series["CSn"].Points.AddXY(j, last0);
                }
                chart1.Series["CSn"].Points.AddXY(j, cur0);

                if (cur1 != last1)
                {
                    chart2.Series["SO "].Points.AddXY(j, last1);
                }
                chart2.Series["SO "].Points.AddXY(j, cur1);

                if (cur2 != last2)
                {
                    chart3.Series["SI "].Points.AddXY(j, last2);
                }
                chart3.Series["SI "].Points.AddXY(j, cur2);

                if (cur3 != last3)
                {
                    chart4.Series["SCK"].Points.AddXY(j, last3);
                }
                chart4.Series["SCK"].Points.AddXY(j, cur3);
            }
        }

        private void btnGeneric_Click(object sender, EventArgs e)
        {
            //We get 4 bytes in row per bit selector control.
            //Since we are chaining two bit selector controls together,
            //we need to manually interleave that as expected from a GUI perspective.

            //Word0
            serialPort.Write(bitSelector1.RawData, 0, 1);
            serialPort.Write(bitSelector2.RawData, 0, 1);          

            //Word1
            serialPort.Write(bitSelector1.RawData, 1, 1);
            serialPort.Write(bitSelector2.RawData, 1, 1);         

            //Word2
            serialPort.Write(bitSelector1.RawData, 2, 1);
            serialPort.Write(bitSelector2.RawData, 2, 1);         

            //Word3
            serialPort.Write(bitSelector1.RawData, 3, 1);
            serialPort.Write(bitSelector2.RawData, 3, 1);
          
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

        private void btnClearLocal_Click(object sender, EventArgs e)
        {
            txtLocal.Clear();
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
            chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            chart2.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            chart3.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;

            chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            chart2.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            chart3.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
        }

        
        private void chart1_AxisViewChanged(object sender, ViewEventArgs e)
        {
            //chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            //chart2.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            //chart3.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;
            //chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Size = e.NewSize;

            //chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart2.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart3.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
        }
        private void chart1_SelectionRangeChanged(object sender, CursorEventArgs e)
        {
            
            //chart1.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart2.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart3.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            //chart4.ChartAreas["ChartArea1"].AxisX.ScaleView.Position = e.NewPosition;
            
        }             

        private void chart1_SelectionRangeChanging(object sender, CursorEventArgs e)
        {
            ////chart1.ChartAreas["ChartArea1"].CursorX.SelectionEnd


            //chart1.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart1.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
            //chart2.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart2.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
            //chart3.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart3.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
            //chart4.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart4.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;

            //chart1.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            //chart2.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            //chart3.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            //chart4.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;

        }

        private void chart1_CursorPositionChanging(object sender, CursorEventArgs e)
        {
            chart1.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            chart2.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            chart3.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;
            chart4.ChartAreas["ChartArea1"].CursorX.Position = e.NewPosition;

            //chart1.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart1.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
            //chart2.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart2.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
            //chart3.ChartAreas["ChartArea1"].CursorX.SelectionStart = e.NewSelectionStart;
            //chart3.ChartAreas["ChartArea1"].CursorX.SelectionEnd = e.NewSelectionEnd;
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

       

       

       

        

    }
}
