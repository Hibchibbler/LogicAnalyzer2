namespace GizyitClient
{
    partial class frmMain
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea5 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend5 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series5 = new System.Windows.Forms.DataVisualization.Charting.Series();
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea6 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend6 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series6 = new System.Windows.Forms.DataVisualization.Charting.Series();
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea7 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend7 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series7 = new System.Windows.Forms.DataVisualization.Charting.Series();
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea8 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend8 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series8 = new System.Windows.Forms.DataVisualization.Charting.Series();
            this.chart1 = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.chart2 = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.chart3 = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.chart4 = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.btnConnect = new System.Windows.Forms.Button();
            this.txtCOMPortNumber = new System.Windows.Forms.TextBox();
            this.txtBaudrate = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.txtRemote = new System.Windows.Forms.TextBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.label6 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.txtMaxPreTriggerSampleCount = new System.Windows.Forms.TextBox();
            this.txtMaxSampleCount = new System.Windows.Forms.TextBox();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.chbxEdgeType = new System.Windows.Forms.CheckBox();
            this.chbxPatternTriggerEnable = new System.Windows.Forms.CheckBox();
            this.chbxEdgeTriggerEnable = new System.Windows.Forms.CheckBox();
            this.txtEdgeChannel = new System.Windows.Forms.TextBox();
            this.txtDontCareChannels = new System.Windows.Forms.TextBox();
            this.label11 = new System.Windows.Forms.Label();
            this.label10 = new System.Windows.Forms.Label();
            this.label9 = new System.Windows.Forms.Label();
            this.label8 = new System.Windows.Forms.Label();
            this.txtDesiredPattern = new System.Windows.Forms.TextBox();
            this.txtActiveChannels = new System.Windows.Forms.TextBox();
            this.tabPage4 = new System.Windows.Forms.TabPage();
            this.btnGetBuffCfg = new System.Windows.Forms.Button();
            this.btnResetHW = new System.Windows.Forms.Button();
            this.btnGetTriggerSample = new System.Windows.Forms.Button();
            this.btnGetTrace = new System.Windows.Forms.Button();
            this.btnAbort = new System.Windows.Forms.Button();
            this.btnStart = new System.Windows.Forms.Button();
            this.btnSetTrigCfg = new System.Windows.Forms.Button();
            this.btnGetTrigCfg = new System.Windows.Forms.Button();
            this.btnGetTraceSize = new System.Windows.Forms.Button();
            this.btnGetStatus = new System.Windows.Forms.Button();
            this.btnSetBuffCfg = new System.Windows.Forms.Button();
            this.worker = new System.ComponentModel.BackgroundWorker();
            this.serialPort = new System.IO.Ports.SerialPort(this.components);
            this.btnClear = new System.Windows.Forms.Button();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.loadTraceToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveTraceAsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.txtLocal = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.btnClearLocal = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.chart1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart2)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart3)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart4)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.tabControl1.SuspendLayout();
            this.tabPage1.SuspendLayout();
            this.tabPage2.SuspendLayout();
            this.tabPage4.SuspendLayout();
            this.menuStrip1.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // chart1
            // 
            this.chart1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            chartArea5.AxisX.MajorGrid.Enabled = false;
            chartArea5.AxisY.MajorGrid.Enabled = false;
            chartArea5.Name = "ChartArea1";
            this.chart1.ChartAreas.Add(chartArea5);
            legend5.Name = "Legend1";
            this.chart1.Legends.Add(legend5);
            this.chart1.Location = new System.Drawing.Point(0, 26);
            this.chart1.Name = "chart1";
            series5.ChartArea = "ChartArea1";
            series5.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Spline;
            series5.Legend = "Legend1";
            series5.Name = "Series1";
            this.chart1.Series.Add(series5);
            this.chart1.Size = new System.Drawing.Size(931, 97);
            this.chart1.TabIndex = 0;
            this.chart1.Text = "mainChart";
            this.chart1.CursorPositionChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanging);
            this.chart1.CursorPositionChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanged);
            this.chart1.SelectionRangeChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanging);
            this.chart1.SelectionRangeChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanged);
            this.chart1.AxisViewChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanging);
            this.chart1.AxisViewChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanged);
            // 
            // chart2
            // 
            this.chart2.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            chartArea6.AxisX.MajorGrid.Enabled = false;
            chartArea6.AxisY.MajorGrid.Enabled = false;
            chartArea6.Name = "ChartArea1";
            this.chart2.ChartAreas.Add(chartArea6);
            legend6.Name = "Legend1";
            this.chart2.Legends.Add(legend6);
            this.chart2.Location = new System.Drawing.Point(0, 126);
            this.chart2.Name = "chart2";
            series6.ChartArea = "ChartArea1";
            series6.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Spline;
            series6.Legend = "Legend1";
            series6.Name = "Series1";
            this.chart2.Series.Add(series6);
            this.chart2.Size = new System.Drawing.Size(931, 97);
            this.chart2.TabIndex = 16;
            this.chart2.Text = "mainChart";
            this.chart2.CursorPositionChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanging);
            this.chart2.CursorPositionChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanged);
            this.chart2.SelectionRangeChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanging);
            this.chart2.SelectionRangeChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanged);
            this.chart2.AxisViewChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanging);
            this.chart2.AxisViewChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanged);
            // 
            // chart3
            // 
            this.chart3.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            chartArea7.AxisX.MajorGrid.Enabled = false;
            chartArea7.AxisY.MajorGrid.Enabled = false;
            chartArea7.Name = "ChartArea1";
            this.chart3.ChartAreas.Add(chartArea7);
            legend7.Name = "Legend1";
            this.chart3.Legends.Add(legend7);
            this.chart3.Location = new System.Drawing.Point(0, 227);
            this.chart3.Name = "chart3";
            series7.ChartArea = "ChartArea1";
            series7.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Spline;
            series7.Legend = "Legend1";
            series7.Name = "Series1";
            this.chart3.Series.Add(series7);
            this.chart3.Size = new System.Drawing.Size(931, 97);
            this.chart3.TabIndex = 17;
            this.chart3.Text = "mainChart";
            this.chart3.CursorPositionChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanging);
            this.chart3.CursorPositionChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanged);
            this.chart3.SelectionRangeChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanging);
            this.chart3.SelectionRangeChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanged);
            this.chart3.AxisViewChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanging);
            this.chart3.AxisViewChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanged);
            // 
            // chart4
            // 
            this.chart4.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right)));
            chartArea8.AxisX.MajorGrid.Enabled = false;
            chartArea8.AxisY.MajorGrid.Enabled = false;
            chartArea8.Name = "ChartArea1";
            this.chart4.ChartAreas.Add(chartArea8);
            legend8.Name = "Legend1";
            this.chart4.Legends.Add(legend8);
            this.chart4.Location = new System.Drawing.Point(0, 327);
            this.chart4.Name = "chart4";
            series8.ChartArea = "ChartArea1";
            series8.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Spline;
            series8.Legend = "Legend1";
            series8.Name = "Series1";
            this.chart4.Series.Add(series8);
            this.chart4.Size = new System.Drawing.Size(931, 97);
            this.chart4.TabIndex = 18;
            this.chart4.Text = "mainChart";
            this.chart4.CursorPositionChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanging);
            this.chart4.CursorPositionChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_CursorPositionChanged);
            this.chart4.SelectionRangeChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanging);
            this.chart4.SelectionRangeChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.CursorEventArgs>(this.chart1_SelectionRangeChanged);
            this.chart4.AxisViewChanging += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanging);
            this.chart4.AxisViewChanged += new System.EventHandler<System.Windows.Forms.DataVisualization.Charting.ViewEventArgs>(this.chart1_AxisViewChanged);
            // 
            // btnConnect
            // 
            this.btnConnect.Location = new System.Drawing.Point(12, 112);
            this.btnConnect.Name = "btnConnect";
            this.btnConnect.Size = new System.Drawing.Size(100, 23);
            this.btnConnect.TabIndex = 1;
            this.btnConnect.Text = "Connect";
            this.btnConnect.UseVisualStyleBackColor = true;
            this.btnConnect.Click += new System.EventHandler(this.btnConnect_Click);
            // 
            // txtCOMPortNumber
            // 
            this.txtCOMPortNumber.Location = new System.Drawing.Point(12, 31);
            this.txtCOMPortNumber.Name = "txtCOMPortNumber";
            this.txtCOMPortNumber.Size = new System.Drawing.Size(100, 20);
            this.txtCOMPortNumber.TabIndex = 2;
            this.txtCOMPortNumber.Text = "8";
            // 
            // txtBaudrate
            // 
            this.txtBaudrate.Location = new System.Drawing.Point(12, 78);
            this.txtBaudrate.Name = "txtBaudrate";
            this.txtBaudrate.Size = new System.Drawing.Size(100, 20);
            this.txtBaudrate.TabIndex = 3;
            this.txtBaudrate.Text = "115200";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(15, 16);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(63, 13);
            this.label1.TabIndex = 4;
            this.label1.Text = "COM Port #";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(15, 63);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(53, 13);
            this.label2.TabIndex = 5;
            this.label2.Text = "Baud rate";
            // 
            // txtRemote
            // 
            this.txtRemote.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtRemote.Location = new System.Drawing.Point(8, 31);
            this.txtRemote.Multiline = true;
            this.txtRemote.Name = "txtRemote";
            this.txtRemote.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtRemote.Size = new System.Drawing.Size(227, 160);
            this.txtRemote.TabIndex = 8;
            // 
            // groupBox1
            // 
            this.groupBox1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.btnConnect);
            this.groupBox1.Controls.Add(this.txtCOMPortNumber);
            this.groupBox1.Controls.Add(this.txtBaudrate);
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Location = new System.Drawing.Point(0, 428);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(128, 202);
            this.groupBox1.TabIndex = 9;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Analyzer Connection";
            // 
            // groupBox2
            // 
            this.groupBox2.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.groupBox2.Controls.Add(this.tabControl1);
            this.groupBox2.Location = new System.Drawing.Point(134, 428);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(325, 202);
            this.groupBox2.TabIndex = 10;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Analyzer Control";
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tabPage1);
            this.tabControl1.Controls.Add(this.tabPage2);
            this.tabControl1.Controls.Add(this.tabPage4);
            this.tabControl1.Location = new System.Drawing.Point(0, 16);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(325, 180);
            this.tabControl1.TabIndex = 9;
            // 
            // tabPage1
            // 
            this.tabPage1.Controls.Add(this.label6);
            this.tabPage1.Controls.Add(this.label5);
            this.tabPage1.Controls.Add(this.txtMaxPreTriggerSampleCount);
            this.tabPage1.Controls.Add(this.txtMaxSampleCount);
            this.tabPage1.Location = new System.Drawing.Point(4, 22);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage1.Size = new System.Drawing.Size(317, 154);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "Buffer";
            this.tabPage1.UseVisualStyleBackColor = true;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(8, 31);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(148, 13);
            this.label6.TabIndex = 3;
            this.label6.Text = "Max PreTrigger Sample Count";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(60, 11);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(96, 13);
            this.label5.TabIndex = 2;
            this.label5.Text = "Max Sample Count";
            // 
            // txtMaxPreTriggerSampleCount
            // 
            this.txtMaxPreTriggerSampleCount.Location = new System.Drawing.Point(162, 28);
            this.txtMaxPreTriggerSampleCount.Name = "txtMaxPreTriggerSampleCount";
            this.txtMaxPreTriggerSampleCount.Size = new System.Drawing.Size(134, 20);
            this.txtMaxPreTriggerSampleCount.TabIndex = 1;
            this.txtMaxPreTriggerSampleCount.Text = "0";
            // 
            // txtMaxSampleCount
            // 
            this.txtMaxSampleCount.Location = new System.Drawing.Point(162, 8);
            this.txtMaxSampleCount.Name = "txtMaxSampleCount";
            this.txtMaxSampleCount.Size = new System.Drawing.Size(134, 20);
            this.txtMaxSampleCount.TabIndex = 0;
            this.txtMaxSampleCount.Text = "500";
            // 
            // tabPage2
            // 
            this.tabPage2.Controls.Add(this.chbxEdgeType);
            this.tabPage2.Controls.Add(this.chbxPatternTriggerEnable);
            this.tabPage2.Controls.Add(this.chbxEdgeTriggerEnable);
            this.tabPage2.Controls.Add(this.txtEdgeChannel);
            this.tabPage2.Controls.Add(this.txtDontCareChannels);
            this.tabPage2.Controls.Add(this.label11);
            this.tabPage2.Controls.Add(this.label10);
            this.tabPage2.Controls.Add(this.label9);
            this.tabPage2.Controls.Add(this.label8);
            this.tabPage2.Controls.Add(this.txtDesiredPattern);
            this.tabPage2.Controls.Add(this.txtActiveChannels);
            this.tabPage2.Location = new System.Drawing.Point(4, 22);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage2.Size = new System.Drawing.Size(317, 154);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "Triggers";
            this.tabPage2.UseVisualStyleBackColor = true;
            // 
            // chbxEdgeType
            // 
            this.chbxEdgeType.AutoSize = true;
            this.chbxEdgeType.Location = new System.Drawing.Point(33, 94);
            this.chbxEdgeType.Name = "chbxEdgeType";
            this.chbxEdgeType.Size = new System.Drawing.Size(78, 17);
            this.chbxEdgeType.TabIndex = 19;
            this.chbxEdgeType.Text = "Edge Type";
            this.chbxEdgeType.UseVisualStyleBackColor = true;
            // 
            // chbxPatternTriggerEnable
            // 
            this.chbxPatternTriggerEnable.AutoSize = true;
            this.chbxPatternTriggerEnable.Location = new System.Drawing.Point(117, 113);
            this.chbxPatternTriggerEnable.Name = "chbxPatternTriggerEnable";
            this.chbxPatternTriggerEnable.Size = new System.Drawing.Size(132, 17);
            this.chbxPatternTriggerEnable.TabIndex = 18;
            this.chbxPatternTriggerEnable.Text = "Pattern Trigger Enable";
            this.chbxPatternTriggerEnable.UseVisualStyleBackColor = true;
            // 
            // chbxEdgeTriggerEnable
            // 
            this.chbxEdgeTriggerEnable.AutoSize = true;
            this.chbxEdgeTriggerEnable.Location = new System.Drawing.Point(117, 94);
            this.chbxEdgeTriggerEnable.Name = "chbxEdgeTriggerEnable";
            this.chbxEdgeTriggerEnable.Size = new System.Drawing.Size(123, 17);
            this.chbxEdgeTriggerEnable.TabIndex = 17;
            this.chbxEdgeTriggerEnable.Text = "Edge Trigger Enable";
            this.chbxEdgeTriggerEnable.UseVisualStyleBackColor = true;
            // 
            // txtEdgeChannel
            // 
            this.txtEdgeChannel.Location = new System.Drawing.Point(117, 68);
            this.txtEdgeChannel.Name = "txtEdgeChannel";
            this.txtEdgeChannel.Size = new System.Drawing.Size(179, 20);
            this.txtEdgeChannel.TabIndex = 16;
            this.txtEdgeChannel.Text = "0";
            // 
            // txtDontCareChannels
            // 
            this.txtDontCareChannels.Location = new System.Drawing.Point(117, 48);
            this.txtDontCareChannels.Name = "txtDontCareChannels";
            this.txtDontCareChannels.Size = new System.Drawing.Size(179, 20);
            this.txtDontCareChannels.TabIndex = 15;
            this.txtDontCareChannels.Text = "65535";
            // 
            // label11
            // 
            this.label11.AutoSize = true;
            this.label11.Location = new System.Drawing.Point(37, 71);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(74, 13);
            this.label11.TabIndex = 11;
            this.label11.Text = "Edge Channel";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(9, 51);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(102, 13);
            this.label10.TabIndex = 10;
            this.label10.Text = "Dont Care Channels";
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(27, 30);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(84, 13);
            this.label9.TabIndex = 9;
            this.label9.Text = "Active Channels";
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(31, 8);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(80, 13);
            this.label8.TabIndex = 8;
            this.label8.Text = "Desired Pattern";
            // 
            // txtDesiredPattern
            // 
            this.txtDesiredPattern.Location = new System.Drawing.Point(117, 8);
            this.txtDesiredPattern.Name = "txtDesiredPattern";
            this.txtDesiredPattern.Size = new System.Drawing.Size(179, 20);
            this.txtDesiredPattern.TabIndex = 5;
            this.txtDesiredPattern.Text = "0";
            // 
            // txtActiveChannels
            // 
            this.txtActiveChannels.Location = new System.Drawing.Point(117, 28);
            this.txtActiveChannels.Name = "txtActiveChannels";
            this.txtActiveChannels.Size = new System.Drawing.Size(179, 20);
            this.txtActiveChannels.TabIndex = 4;
            this.txtActiveChannels.Text = "65535";
            // 
            // tabPage4
            // 
            this.tabPage4.Controls.Add(this.btnGetBuffCfg);
            this.tabPage4.Controls.Add(this.btnResetHW);
            this.tabPage4.Controls.Add(this.btnGetTriggerSample);
            this.tabPage4.Controls.Add(this.btnGetTrace);
            this.tabPage4.Controls.Add(this.btnAbort);
            this.tabPage4.Controls.Add(this.btnStart);
            this.tabPage4.Controls.Add(this.btnSetTrigCfg);
            this.tabPage4.Controls.Add(this.btnGetTrigCfg);
            this.tabPage4.Controls.Add(this.btnGetTraceSize);
            this.tabPage4.Controls.Add(this.btnGetStatus);
            this.tabPage4.Controls.Add(this.btnSetBuffCfg);
            this.tabPage4.Location = new System.Drawing.Point(4, 22);
            this.tabPage4.Name = "tabPage4";
            this.tabPage4.Size = new System.Drawing.Size(317, 154);
            this.tabPage4.TabIndex = 3;
            this.tabPage4.Text = "Control";
            this.tabPage4.UseVisualStyleBackColor = true;
            // 
            // btnGetBuffCfg
            // 
            this.btnGetBuffCfg.Location = new System.Drawing.Point(26, 3);
            this.btnGetBuffCfg.Name = "btnGetBuffCfg";
            this.btnGetBuffCfg.Size = new System.Drawing.Size(74, 23);
            this.btnGetBuffCfg.TabIndex = 21;
            this.btnGetBuffCfg.Text = "Get Buff Cfg";
            this.btnGetBuffCfg.UseVisualStyleBackColor = true;
            this.btnGetBuffCfg.Click += new System.EventHandler(this.btnGetBuffCfg_Click);
            // 
            // btnResetHW
            // 
            this.btnResetHW.Enabled = false;
            this.btnResetHW.Location = new System.Drawing.Point(217, 131);
            this.btnResetHW.Name = "btnResetHW";
            this.btnResetHW.Size = new System.Drawing.Size(74, 23);
            this.btnResetHW.TabIndex = 20;
            this.btnResetHW.Text = "Reset HW";
            this.btnResetHW.UseVisualStyleBackColor = true;
            this.btnResetHW.Click += new System.EventHandler(this.btnResetHW_Click);
            // 
            // btnGetTriggerSample
            // 
            this.btnGetTriggerSample.Location = new System.Drawing.Point(61, 61);
            this.btnGetTriggerSample.Name = "btnGetTriggerSample";
            this.btnGetTriggerSample.Size = new System.Drawing.Size(74, 23);
            this.btnGetTriggerSample.TabIndex = 19;
            this.btnGetTriggerSample.Text = "Get TrSamp";
            this.btnGetTriggerSample.UseVisualStyleBackColor = true;
            this.btnGetTriggerSample.Click += new System.EventHandler(this.btnGetTriggerSample_Click);
            // 
            // btnGetTrace
            // 
            this.btnGetTrace.Location = new System.Drawing.Point(61, 119);
            this.btnGetTrace.Name = "btnGetTrace";
            this.btnGetTrace.Size = new System.Drawing.Size(74, 23);
            this.btnGetTrace.TabIndex = 18;
            this.btnGetTrace.Text = "Get Trace";
            this.btnGetTrace.UseVisualStyleBackColor = true;
            this.btnGetTrace.Click += new System.EventHandler(this.btnGetTrace_Click);
            // 
            // btnAbort
            // 
            this.btnAbort.Location = new System.Drawing.Point(217, 32);
            this.btnAbort.Name = "btnAbort";
            this.btnAbort.Size = new System.Drawing.Size(74, 23);
            this.btnAbort.TabIndex = 17;
            this.btnAbort.Text = "Abort";
            this.btnAbort.UseVisualStyleBackColor = true;
            this.btnAbort.Click += new System.EventHandler(this.btnAbort_Click);
            // 
            // btnStart
            // 
            this.btnStart.Location = new System.Drawing.Point(217, 3);
            this.btnStart.Name = "btnStart";
            this.btnStart.Size = new System.Drawing.Size(74, 23);
            this.btnStart.TabIndex = 16;
            this.btnStart.Text = "Start";
            this.btnStart.UseVisualStyleBackColor = true;
            this.btnStart.Click += new System.EventHandler(this.btnStart_Click);
            // 
            // btnSetTrigCfg
            // 
            this.btnSetTrigCfg.Location = new System.Drawing.Point(106, 32);
            this.btnSetTrigCfg.Name = "btnSetTrigCfg";
            this.btnSetTrigCfg.Size = new System.Drawing.Size(74, 23);
            this.btnSetTrigCfg.TabIndex = 15;
            this.btnSetTrigCfg.Text = "Set Trig Cfg";
            this.btnSetTrigCfg.UseVisualStyleBackColor = true;
            this.btnSetTrigCfg.Click += new System.EventHandler(this.btnSetTrigCfg_Click);
            // 
            // btnGetTrigCfg
            // 
            this.btnGetTrigCfg.Location = new System.Drawing.Point(106, 3);
            this.btnGetTrigCfg.Name = "btnGetTrigCfg";
            this.btnGetTrigCfg.Size = new System.Drawing.Size(74, 23);
            this.btnGetTrigCfg.TabIndex = 14;
            this.btnGetTrigCfg.Text = "Get Trig Cfg";
            this.btnGetTrigCfg.UseVisualStyleBackColor = true;
            this.btnGetTrigCfg.Click += new System.EventHandler(this.btnGetTrigCfg_Click);
            // 
            // btnGetTraceSize
            // 
            this.btnGetTraceSize.Location = new System.Drawing.Point(61, 90);
            this.btnGetTraceSize.Name = "btnGetTraceSize";
            this.btnGetTraceSize.Size = new System.Drawing.Size(74, 23);
            this.btnGetTraceSize.TabIndex = 13;
            this.btnGetTraceSize.Text = "Get TrSize";
            this.btnGetTraceSize.UseVisualStyleBackColor = true;
            this.btnGetTraceSize.Click += new System.EventHandler(this.btnGetTraceSize_Click);
            // 
            // btnGetStatus
            // 
            this.btnGetStatus.Location = new System.Drawing.Point(217, 61);
            this.btnGetStatus.Name = "btnGetStatus";
            this.btnGetStatus.Size = new System.Drawing.Size(74, 23);
            this.btnGetStatus.TabIndex = 12;
            this.btnGetStatus.Text = "Get Status";
            this.btnGetStatus.UseVisualStyleBackColor = true;
            this.btnGetStatus.Click += new System.EventHandler(this.btnGetStatus_Click);
            // 
            // btnSetBuffCfg
            // 
            this.btnSetBuffCfg.Location = new System.Drawing.Point(26, 32);
            this.btnSetBuffCfg.Name = "btnSetBuffCfg";
            this.btnSetBuffCfg.Size = new System.Drawing.Size(74, 23);
            this.btnSetBuffCfg.TabIndex = 11;
            this.btnSetBuffCfg.Text = "Set Buff Cfg";
            this.btnSetBuffCfg.UseVisualStyleBackColor = true;
            this.btnSetBuffCfg.Click += new System.EventHandler(this.btnSetBuffCfg_Click);
            // 
            // worker
            // 
            this.worker.WorkerReportsProgress = true;
            this.worker.WorkerSupportsCancellation = true;
            this.worker.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker1_DoWork);
            this.worker.ProgressChanged += new System.ComponentModel.ProgressChangedEventHandler(this.backgroundWorker1_ProgressChanged);
            // 
            // btnClear
            // 
            this.btnClear.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnClear.Location = new System.Drawing.Point(173, 11);
            this.btnClear.Name = "btnClear";
            this.btnClear.Size = new System.Drawing.Size(62, 25);
            this.btnClear.TabIndex = 11;
            this.btnClear.Text = "Clear";
            this.btnClear.UseVisualStyleBackColor = true;
            this.btnClear.Click += new System.EventHandler(this.btnClear_Click);
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(937, 24);
            this.menuStrip1.TabIndex = 12;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // fileToolStripMenuItem
            // 
            this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.loadTraceToolStripMenuItem,
            this.saveTraceAsToolStripMenuItem});
            this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
            this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
            this.fileToolStripMenuItem.Text = "&File";
            // 
            // loadTraceToolStripMenuItem
            // 
            this.loadTraceToolStripMenuItem.Name = "loadTraceToolStripMenuItem";
            this.loadTraceToolStripMenuItem.Size = new System.Drawing.Size(152, 22);
            this.loadTraceToolStripMenuItem.Text = "&Load Trace...";
            this.loadTraceToolStripMenuItem.Click += new System.EventHandler(this.loadTraceToolStripMenuItem_Click);
            // 
            // saveTraceAsToolStripMenuItem
            // 
            this.saveTraceAsToolStripMenuItem.Name = "saveTraceAsToolStripMenuItem";
            this.saveTraceAsToolStripMenuItem.Size = new System.Drawing.Size(152, 22);
            this.saveTraceAsToolStripMenuItem.Text = "&Save Trace as...";
            this.saveTraceAsToolStripMenuItem.Click += new System.EventHandler(this.saveTraceAsToolStripMenuItem_Click);
            // 
            // txtLocal
            // 
            this.txtLocal.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtLocal.Location = new System.Drawing.Point(239, 31);
            this.txtLocal.Multiline = true;
            this.txtLocal.Name = "txtLocal";
            this.txtLocal.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtLocal.Size = new System.Drawing.Size(227, 160);
            this.txtLocal.TabIndex = 13;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(236, 17);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(33, 13);
            this.label3.TabIndex = 14;
            this.label3.Text = "Local";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(6, 17);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(44, 13);
            this.label4.TabIndex = 9;
            this.label4.Text = "Remote";
            // 
            // groupBox3
            // 
            this.groupBox3.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.groupBox3.Controls.Add(this.label4);
            this.groupBox3.Controls.Add(this.txtLocal);
            this.groupBox3.Controls.Add(this.label3);
            this.groupBox3.Controls.Add(this.txtRemote);
            this.groupBox3.Controls.Add(this.btnClear);
            this.groupBox3.Controls.Add(this.btnClearLocal);
            this.groupBox3.Location = new System.Drawing.Point(465, 428);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(472, 202);
            this.groupBox3.TabIndex = 15;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Information";
            // 
            // btnClearLocal
            // 
            this.btnClearLocal.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnClearLocal.Location = new System.Drawing.Point(404, 11);
            this.btnClearLocal.Name = "btnClearLocal";
            this.btnClearLocal.Size = new System.Drawing.Size(62, 25);
            this.btnClearLocal.TabIndex = 15;
            this.btnClearLocal.Text = "Clear";
            this.btnClearLocal.UseVisualStyleBackColor = true;
            this.btnClearLocal.Click += new System.EventHandler(this.btnClearLocal_Click);
            // 
            // frmMain
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(937, 631);
            this.Controls.Add(this.chart1);
            this.Controls.Add(this.chart4);
            this.Controls.Add(this.chart2);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.chart3);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.menuStrip1);
            this.MainMenuStrip = this.menuStrip1;
            this.Name = "frmMain";
            this.Text = "Gizyit Client";
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.frmMain_FormClosed);
            this.Load += new System.EventHandler(this.frmMain_Load);
            ((System.ComponentModel.ISupportInitialize)(this.chart1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart2)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart3)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.chart4)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.groupBox2.ResumeLayout(false);
            this.tabControl1.ResumeLayout(false);
            this.tabPage1.ResumeLayout(false);
            this.tabPage1.PerformLayout();
            this.tabPage2.ResumeLayout(false);
            this.tabPage2.PerformLayout();
            this.tabPage4.ResumeLayout(false);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.groupBox3.ResumeLayout(false);
            this.groupBox3.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.DataVisualization.Charting.Chart chart1;
        private System.Windows.Forms.DataVisualization.Charting.Chart chart2;
        private System.Windows.Forms.DataVisualization.Charting.Chart chart3;
        private System.Windows.Forms.DataVisualization.Charting.Chart chart4;
        private System.Windows.Forms.Button btnConnect;
        private System.Windows.Forms.TextBox txtCOMPortNumber;
        private System.Windows.Forms.TextBox txtBaudrate;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox txtRemote;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.ComponentModel.BackgroundWorker worker;
        private System.IO.Ports.SerialPort serialPort;
        private System.Windows.Forms.Button btnClear;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.TextBox txtLocal;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.Button btnClearLocal;
        private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem loadTraceToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveTraceAsToolStripMenuItem;
        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tabPage1;
        private System.Windows.Forms.TabPage tabPage2;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.TextBox txtMaxPreTriggerSampleCount;
        private System.Windows.Forms.TextBox txtMaxSampleCount;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TextBox txtDesiredPattern;
        private System.Windows.Forms.TextBox txtActiveChannels;
        private System.Windows.Forms.CheckBox chbxEdgeType;
        private System.Windows.Forms.CheckBox chbxPatternTriggerEnable;
        private System.Windows.Forms.CheckBox chbxEdgeTriggerEnable;
        private System.Windows.Forms.TextBox txtEdgeChannel;
        private System.Windows.Forms.TextBox txtDontCareChannels;
        private System.Windows.Forms.Label label11;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.Button btnGetStatus;
        private System.Windows.Forms.Button btnSetBuffCfg;
        private System.Windows.Forms.TabPage tabPage4;
        private System.Windows.Forms.Button btnResetHW;
        private System.Windows.Forms.Button btnGetTriggerSample;
        private System.Windows.Forms.Button btnGetTrace;
        private System.Windows.Forms.Button btnAbort;
        private System.Windows.Forms.Button btnStart;
        private System.Windows.Forms.Button btnSetTrigCfg;
        private System.Windows.Forms.Button btnGetTrigCfg;
        private System.Windows.Forms.Button btnGetTraceSize;
        private System.Windows.Forms.Button btnGetBuffCfg;

    }
}

