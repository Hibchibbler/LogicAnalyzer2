`timescale 1ns/1ps

module TriggerTransDetection_TestBench();

    localparam SAMPLE_WIDTH = 8;
    
    reg [SAMPLE_WIDTH-1:0] latestSample;
    reg [SAMPLE_WIDTH-1:0] prevSample;
    reg [SAMPLE_WIDTH-1:0] activeChannels;
    
    integer edgeChannel;
    reg edgeType;
    reg edgeTriggerEnabled;
    
    reg patternTriggerEnabled;
    reg [SAMPLE_WIDTH-1:0] desiredPattern;
    reg [SAMPLE_WIDTH-1:0] dontCareChannels;
    
    wire triggered;
    wire transition;

    integer failedAssertionCount;
    integer assertionCount;
    
    initial begin
        $dumpfile("TriggerTransDetection.vcd");
        $dumpvars(0,TriggerTransDetection_TestBench);
        failedAssertionCount = 0;
        assertionCount = 0;
    end
    
    TriggerTransDetection #(.SAMPLE_WIDTH(SAMPLE_WIDTH))  dut (
        .latestSample(latestSample),
        .previousSample(prevSample),
        .activeChannels(activeChannels),
        .edgeChannel(edgeChannel),
        .edgeType(edgeType),
        .edgeTriggerEnabled(edgeTriggerEnabled),
        .patternTriggerEnabled(patternTriggerEnabled),
        .desiredPattern(desiredPattern),
        .dontCareChannels(dontCareChannels),
        .triggered(triggered),
        .transition(transition)
    );
    
    task delay;
    begin
        #1;
    end
    endtask
    
    task assertVal (input expected, input actual, input [1023:0] comment);
    begin
        assertionCount = assertionCount + 1;
        if (expected !== actual) begin
            $display("Assertion Failure. Expected: %b  Actual: %b   Comment: %s", expected, actual, comment);
            failedAssertionCount = failedAssertionCount + 1;
        end
    end
    endtask
    
    task printSummary;
    begin
        $display("Failed %d of %d total assertions", failedAssertionCount, assertionCount);
    end
    endtask
    
    task setSampleBits(input integer bitNum, input latest, input prev);
    begin
        latestSample[bitNum] = latest;
        prevSample[bitNum]   = prev;
    end
    endtask
    
    task setPositiveEdge(input integer bitNum);
    begin
        latestSample = 0;
        prevSample  = 0;
        setSampleBits(bitNum, 1, 0);
    end
    endtask
    
    task setNegativeEdge(input integer bitNum);
    begin
        latestSample = 0;
        prevSample  = 0;
        setSampleBits(bitNum, 0, 1);    
    end
    endtask
    
    integer i;
    integer j;
    reg [2055:0] commentString;
    task testEdgeTrigger;
    begin
        initState;
        edgeTriggerEnabled = 1;
        patternTriggerEnabled = 0;
        for ( i = 0; i < SAMPLE_WIDTH; i = i + 1) begin
            edgeChannel = i;
            for (j = 0; j < SAMPLE_WIDTH; j = j + 1) begin
                // Test Positive Edge Trigger Condition:
                setPositiveEdge(j);
                edgeType = 1;
                delay;
                $sformat(commentString, "\nEdge Channel: %d , Edge Type: %b, Positive Edge On Channel %d", edgeChannel, edgeType, j);
                assertVal( i === j, triggered, commentString);
                assertVal( i === j, dut.edgeTrigger, commentString);
                edgeType = 0;
                delay;
                assertVal(0, triggered, commentString);
                assertVal(0, dut.edgeTrigger, commentString);
                // Negative Edge
                setNegativeEdge(j);
                edgeType = 0;
                delay;
                $sformat(commentString, "\nEdge Channel: %d, Edge Type: %b, Negative Edge On Channel %d", edgeChannel, edgeType, j);
                assertVal(i === j, triggered, commentString);
                assertVal(i === j, dut.edgeTrigger, commentString);
                edgeType = 1;
                delay;
                assertVal(0, triggered, commentString);
                assertVal(0, dut.edgeTrigger, commentString);
            end
        end    
    end
    endtask
    
    reg [SAMPLE_WIDTH-1:0] sampleLoopVar;
    reg [SAMPLE_WIDTH-1:0] desiredLoopVar;
    reg [SAMPLE_WIDTH-1:0] activeChannelLoopVar;
    reg [SAMPLE_WIDTH-1:0] dontCareLoopVar;
    integer k;
    reg sValue; // sample value
    reg dValue; // 
    reg aValue;
    reg cValue;
    reg matchTrue;
    task testPatternTrigger;
    begin
        initState;
        edgeTriggerEnabled = 0;
        patternTriggerEnabled = 1;
        for (sampleLoopVar = 0; sampleLoopVar < (1 << SAMPLE_WIDTH-1); sampleLoopVar = sampleLoopVar + 4) begin
            latestSample = sampleLoopVar;
            for (desiredLoopVar = 0; desiredLoopVar < (1 << SAMPLE_WIDTH-1); desiredLoopVar = desiredLoopVar + 4) begin
                desiredPattern = desiredLoopVar;
                for (activeChannelLoopVar = 0; activeChannelLoopVar < (1 << SAMPLE_WIDTH-1); activeChannelLoopVar = activeChannelLoopVar + 4) begin
                    activeChannels = activeChannelLoopVar;
                    for (dontCareLoopVar = 0; dontCareLoopVar < (1 << SAMPLE_WIDTH-1); dontCareLoopVar = dontCareLoopVar + 16) begin
                        dontCareChannels = dontCareLoopVar;
                        matchTrue = 1;
                        for (k = 0; k < SAMPLE_WIDTH; k = k + 1) begin
                            sValue = sampleLoopVar[k];
                            dValue = desiredLoopVar[k];
                            aValue = activeChannelLoopVar[k];
                            cValue = dontCareLoopVar[k];
                            if (~cValue & aValue) begin
                                if (sValue !== dValue) begin
                                    matchTrue = 0;
                                end
                            end
                        end
                        delay;
                        $sformat(commentString, "Sample: %b  Desired: %b  Active Channels: %b  Dont Cares: %b", sampleLoopVar, desiredLoopVar, activeChannelLoopVar, dontCareLoopVar);
                        assertVal(matchTrue, triggered, commentString);
                        assertVal(matchTrue, dut.patternTrigger, commentString);
                    end
                end
            end
        end
    end
    endtask
    
    task initState;
    begin
        latestSample = 0;
        prevSample = 0;
        activeChannels = 0;
        edgeChannel = 0;
        edgeType = 0;
        edgeTriggerEnabled = 0;
        patternTriggerEnabled = 0;
        desiredPattern = 0;
        dontCareChannels = 0;
        delay;
        assertVal(1, triggered, "Initial - Both Triggers Disabled, Trigger signal active");
        assertVal(0, transition, "Initial - No Active Channels, No Possible Transition.");
    end
    endtask
    
    task comboTriggerTesting;
    begin
        initState;
        edgeTriggerEnabled = 1;
        patternTriggerEnabled = 1;
        // Tests to ensure combination of triggers works properly
        // Case 1: Edge trigger true, pattern false.
        edgeChannel = 0;
        edgeType = 1;
        setSampleBits(0,1,0);
        setSampleBits(1,1,1);
        activeChannels = ~0;
        delay;
        assertVal(0, dut.patternTrigger, "Case 1, verify pattern trigger false");
        assertVal(1, dut.edgeTrigger, "Case 1, verify edge trigger true");
        assertVal(0, triggered, "Case 1, verify triggered output false");
        // Case 2: Edge Trigger True, Pattern True
        setSampleBits(1,0,0);
        desiredPattern = 1;
        delay;
        assertVal(1, dut.patternTrigger, "Case 2, verify pattern trigger true");
        assertVal(1, dut.edgeTrigger, "Case 2, verify edge trigger true");
        assertVal(1, triggered, "Case 2, verify triggered output true");
        // Case 3: Edge Trigger False, Pattern True
        setSampleBits(0,1,1);
        delay;
        assertVal(1, dut.patternTrigger, "Case 3, verify pattern trigger true");
        assertVal(0, dut.edgeTrigger, "Case 3, verify edge trigger false");
        assertVal(0, triggered, "Case 3, verify triggered output false");
        // Case 4: Edge Trigger False, Pattern False
        desiredPattern = 0;
        delay;
        assertVal(0, dut.patternTrigger, "Case 4, verify pattern trigger false");
        assertVal(0, dut.edgeTrigger, "Case 4, verify edge trigger false");
        assertVal(0, triggered, "Case 4, verify triggered output false");        
    end
    endtask
    
    reg [31:0] randVar0;
    reg [31:0] randVar1;
    reg [31:0] randVar2;
    integer tLoopVar;
    integer sLoopVar;
    reg transFound;
    task testTransitionLogic;
    begin
        initState;
        activeChannels = ~(0);
        for (tLoopVar = 0; tLoopVar < 100000; tLoopVar = tLoopVar + 1) begin
            randVar0 = $random;
            randVar1 = $random;
            latestSample = randVar0;
            prevSample   = randVar0;
            delay;
            assertVal(0, transition, "Current and Previous Sample are the same, all active channels, no transition detected");
            prevSample = randVar1;
            delay;
            $sformat(commentString,"\nCurrent and previous and random values, all channels active, transition likely. Latest Sample: %b  Prev Sample: %b", latestSample, prevSample);
            assertVal(latestSample !== prevSample, transition, commentString);
        end
        for (tLoopVar = 0; tLoopVar < 100000; tLoopVar = tLoopVar + 1) begin
            randVar0 = $random;
            randVar1 = $random;
            randVar2 = $random;
            activeChannels = randVar0;
            latestSample = randVar1;
            prevSample = randVar2;
            transFound = 0;
            for (sLoopVar = 0; sLoopVar < SAMPLE_WIDTH; sLoopVar = sLoopVar + 1) begin
                if (activeChannels[sLoopVar]) begin
                    if (latestSample[sLoopVar] !== prevSample[sLoopVar]) begin
                        transFound = 1;
                    end
                end
            end
            delay;
            assertVal(transFound, transition, "Random active channels with random sample values");
        end
    end
    endtask
    
    initial
    begin
        initState;
        testEdgeTrigger;
        //testPatternTrigger;
        comboTriggerTesting;
        testTransitionLogic;
        printSummary;
        $finish;
    end
    
endmodule