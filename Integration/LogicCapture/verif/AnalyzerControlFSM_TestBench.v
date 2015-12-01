module AnalyzerControlFSM_TestBench();

    localparam IDLE                       = 2'b00;
    localparam START_DELAY         = 2'b01;
    localparam RUN_PRETRIGGER   = 2'b10;
    localparam RUN_POSTTRIGGER = 2'b11;

    localparam CLOCK_PERIOD = 2;

    reg clock;
    reg reset;
    
    reg start;
    reg abort;
    reg complete;
    reg sawTrigger;
    
    initial begin
        $dumpfile("AnalyzerControlFSM.vcd");
        $dumpvars(0,AnalyzerControlFSM_TestBench);
        clock       = 1;
        sawTrigger = 0;
        reset       = 1;
        start        = 0;
        abort       = 0;
        complete  = 0;
    end
    
    always begin
        #(CLOCK_PERIOD/2) clock = ~clock;
    end
    
    AnalyzerControlFSM dut(
        .clock(clock),
        .reset(reset),
        .start(start),
        .sawTrigger(sawTrigger),
        .abort(abort),
        .complete(complete),
        .triggered(),
        .running(),
        .idle()
    );
    
    task resetMe;
    begin
        #(CLOCK_PERIOD) reset = 1;
        #(CLOCK_PERIOD) reset = 0;
    end
    endtask
    
    task checkState(
        input [1:0] expectedState,
        input [1:0] actualState,
        input [1023:0] comment
    );
    begin
        if (expectedState !== actualState)
            $display("Error: Expected State: %d   Actual State: %d - %s", expectedState, actualState,comment);
    end
    endtask
    
    
    
    initial begin
        // SEQUENCE 0
        // Normal Sequence - Idle -> Running -> Triggered -> Idle
        #(CLOCK_PERIOD) reset = 0;
        checkState(IDLE,dut.state,"Sequence 0 - Initial");
        #(3*CLOCK_PERIOD) start  = 1;
        #(CLOCK_PERIOD) start  = 0;
        checkState(RUN_PRETRIGGER,dut.state,"Sequence 0 - Started");
        #(5*CLOCK_PERIOD)  sawTrigger = 1;
        #(CLOCK_PERIOD) sawTrigger = 0;
        checkState(RUN_POSTTRIGGER,dut.state,"Sequence 0 - Post Trigger");
        #(CLOCK_PERIOD) complete = 1;
        #(CLOCK_PERIOD) complete = 0;
        checkState(IDLE,dut.state,"Sequence 0 - Initial");
        
        resetMe;
        
        // SEQUENCE 1
        // Abort high does not allow leaving idle state;
        checkState(IDLE,dut.state,"Sequence 1 - Initial");
        #(CLOCK_PERIOD) abort = 1;
        #(CLOCK_PERIOD) start = 1;
        #(CLOCK_PERIOD);
        checkState(IDLE,dut.state,"Sequence 1 - Post");
        #(2*CLOCK_PERIOD) abort = 0; start = 0;
        
        resetMe;
        
        // SEQUENCE 2
        // Abort From running state
        checkState(IDLE,dut.state,"Sequence 2 - Initial");
        #(CLOCK_PERIOD) start = 1;
        #(CLOCK_PERIOD) start = 0;
        checkState(RUN_PRETRIGGER,dut.state,"Sequence 2 - Running Pre Abort");
        #(5*CLOCK_PERIOD) abort = 1;
        #(CLOCK_PERIOD) abort = 0;
        checkState(IDLE,dut.state, "Sequence 2 - Post Abort");
        
        resetMe;
        
        // SEQUENCE 3
        // Abort From running state with triggerSaw high at same time
        checkState(IDLE,dut.state,"Sequence 3 - Initial");
        #(CLOCK_PERIOD) start = 1;
        #(CLOCK_PERIOD) start = 0;
        checkState(RUN_PRETRIGGER,dut.state,"Sequence 3 - Running Pre Abort");
        #(2*CLOCK_PERIOD) sawTrigger = 1; abort = 1;
        #(CLOCK_PERIOD) sawTrigger = 0; abort = 0;
        checkState(IDLE,dut.state, "Sequence 3 - Post Abort");
        
        resetMe;
        
        // SEQUENCE 4
        // Abort From Running Post Trigger
        checkState(IDLE,dut.state,"Sequence 4- Initial");
        #(CLOCK_PERIOD) start = 1;
        #(CLOCK_PERIOD) start = 0; sawTrigger = 1;
        #(CLOCK_PERIOD) sawTrigger = 0;
        checkState(RUN_POSTTRIGGER, dut.state, "Sequence 4 - Running Post Trigger");
        #(5*CLOCK_PERIOD) abort = 1;
        #(CLOCK_PERIOD) abort = 0;
        checkState(IDLE, dut.state, "Sequence 4 - Post Abort");
        
        #(20*CLOCK_PERIOD);
        $finish;
    end
    

endmodule