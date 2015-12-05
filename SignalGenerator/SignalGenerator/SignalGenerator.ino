/*
 *
 *
 *
 *
 */
 
#ifndef _SIGNALGENERATOR_
#define _SIGNALGENERATOR_

#include "Arduino.h"
#include "global.h"


void flattenOutputs(int numChannels) {
    for (int i = 0; i < numChannels; i++) {
        switch (i) {
            case 0: out0 = false;
            case 1: out1 = false;
            case 2: out2 = false;
            case 3: out3 = false;
            case 4: out4 = false;
            case 5: out5 = false;
            case 6: out6 = false;
            case 7: out7 = false;
        }
    }
}

// read all buttons and switches
void readInputs() {
    boolean btnOnTemp;
    boolean btnSeqTemp;
    boolean swSeqTemp;
    btnOnTemp  = !digitalRead(PIN_BTN_ON);
    btnSeqTemp = !digitalRead(PIN_BTN_SEQ);
    swSeqTemp  = !digitalRead(PIN_SW_SEQ);
    btnOnCount  = (btnOn  !=  btnOnTemp) ?  btnOnCount + 1 : 0 ;
    btnSeqCount = (btnSeq != btnSeqTemp) ? btnSeqCount + 1 : 0 ;
    swSeqCount  = (swSeq  !=  swSeqTemp) ?  swSeqCount + 1 : 0 ;
    if (btnOnCount == btnOnCountMax) {
        btnOn = btnOnTemp;
        btnOnCount = 0;
    }
    if (btnSeqCount == btnSeqCountMax) {
        btnSeq = btnSeqTemp;
        btnSeqCount = 0;
    }
    if (swSeqCount == swSeqCountMax) {
        swSeq = swSeqTemp;
        swSeqCount = 0;
    }
}

void processState() {
    // if swSeq is high, increment state counter automagically
    // don't increment states while outputs are off
    if (swSeq && outputSignals) {
        stateCounter++;
        if (stateCounter > stateCounterMax) {
            if (stateNext < NUM_STATES - 1) {
                stateNext++;
            } else {
                stateNext = 0;
            }
            stateCounter = 0;
        }
    } else {
        // otherwise, increment states if user pressed button
        // stateNextAllowed goes low only when button is released
        // thus, user must press and release button to go to next state
        if (btnSeq) {
            if (stateNextAllowed) {
                if (stateNext < NUM_STATES - 1) {
                    stateNext++;
                } else {
                    stateNext = 0;
                }
                stateNextAllowed = 0;
            }
        } else {
            stateNextAllowed = 1;
        }
    }
    if (state != stateNext) {
        // flatten the outputs any time the state changes
        flattenOutputs(8);
        state = stateNext;
    }
}

void processStatusLED() {
    switch (state) {
        case SEQ_0:
            if (frameCounter % TASK_1HZ == 0) { outStatus = !outStatus; }
            break;
        case SEQ_1:
            if (frameCounter % TASK_2HZ == 0) { outStatus = !outStatus; }
            break;
        case SEQ_2:
            if (frameCounter % TASK_5HZ == 0) { outStatus = !outStatus; }
            break;
        case SEQ_3:
            // two blinks
            outStatus = false;
            for (int i = 0; i < 2; i++) {
                if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                    outStatus = true;
                }
            }
            break;
        case SEQ_4:
            // three blinks
            outStatus = false;
            for (int i = 0; i < 3; i++) {
                if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                    outStatus = true;
                }
            }
            break;
        case SEQ_5:
            // four blinks
            outStatus = false;
            for (int i = 0; i < 4; i++) {
                if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                    outStatus = true;
                }
            }
            break;
        case SEQ_6:
            break;
        case SEQ_7:
            break;
        case SEQ_8:
            break;
        case SEQ_9:
            break;
        default:
            break;
    }
    digitalWrite(PIN_STATUS, outStatus);
}

// called at 10KHz so signals can toggle at most at 5KHz
void processOutputs() {
    // toggle outputs on/off
    // outputs are driven low when off
    if (btnOn) {
        if (outputSignalToggleAllowed) {
            outputSignals = !outputSignals;
            outputSignalToggleAllowed = false;
        }
    } else {
        outputSignalToggleAllowed = true;
    }
    
    // drive the output signals
    /*if (!outputSignals) {
        out0 = false;
        out1 = false;
        out2 = false;
        out3 = false;
        out4 = false;
        out5 = false;
        out6 = false;
        out7 = false;
    } else {*/
        switch (state) {
            // signal changes at 10KHz, a 5KHz clock
            case SEQ_0:
                //out0 = !out0;
                out0 = out0 ? false : true;
                out1 = !out1;
                out2 = !out2;
                out3 = !out3;
                out4 = !out4;
                out5 = !out5;
                out6 = !out6;
                out7 = !out7;
                break;
            // pulse generator
            case SEQ_1:
                flattenOutputs(8);
                for (int i = 0; i < 1; i++) {
                    if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                        out0 = true;
                        out1 = true;
                        out2 = true;
                        out3 = true;
                        out4 = true;
                        out5 = true;
                        out6 = true;
                        out7 = true;
                    }
                }
                break;
            // double pulse generator
            case SEQ_2:
                flattenOutputs(8);
                for (int i = 0; i < 2; i++) {
                    if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                        out0 = true;
                        out1 = true;
                        out2 = true;
                        out3 = true;
                        out4 = true;
                        out5 = true;
                        out6 = true;
                        out7 = true;
                    }
                }
                break;
            // double pulse generators with different rates/times held high on each channel
            case SEQ_3:
                flattenOutputs(8);
                for (int i = 0; i < 2; i++) {
                    if (frameCounter < (2000*i+1000) && frameCounter > (2000*i)) {
                        out0 = true;
                    }
                    if (frameCounter < (3000*i+1000) && frameCounter > (3000*i)) {
                        out1 = true;
                    }
                    if (frameCounter < (300*i+100) && frameCounter > (300*i)) {
                        out2 = true;
                    }
                    if (frameCounter < (5000*i+100) && frameCounter > (5000*i)) {
                        out3 = true;
                    }
                }
                for (int i = 0; i < 10; i++) {
                    if (frameCounter < (500*i+500) && frameCounter > (500*i)) {
                        out4 = true;
                    }
                    if (frameCounter < (3000*i+1000) && frameCounter > (3000*i)) {
                        out5 = true;
                    }
                    if (frameCounter < (300*i+100) && frameCounter > (300*i)) {
                        out6 = true;
                    }
                    if (frameCounter < (500*i+200) && frameCounter > (500*i)) {
                        out7 = true;
                    }
                }
                break;
            case SEQ_4:
                break;
            case SEQ_5:
                break;
            case SEQ_6:
                break;
            case SEQ_7:
                break;
            case SEQ_8:
                break;
            case SEQ_9:
                break;
            default:
                break;
        }
    //}
        
    digitalWrite(PIN_OUT_0,   out0);
    digitalWrite(PIN_OUT_1,   out1);
    digitalWrite(PIN_OUT_2,   out2);
    digitalWrite(PIN_OUT_3,   out3);
    digitalWrite(PIN_OUT_4,   out4);
    digitalWrite(PIN_OUT_5,   out5);
    digitalWrite(PIN_OUT_6,   out6);
    digitalWrite(PIN_OUT_7,   out7);
}



// ---------------------------------------------
// 
// ---------------------------------------------
void process10KHz() {
    processOutputs();
}

// read and debounce buttons
// handle state machine
void process100Hz() {
    readInputs();
    processState();
    processStatusLED();
}

void setup() {
    // set up inputs, enable pull-up resistors
    pinMode(PIN_BTN_ON,       INPUT);
    pinMode(PIN_BTN_SEQ,      INPUT);
    pinMode(PIN_SW_SEQ,       INPUT);
    digitalWrite(PIN_BTN_ON,  HIGH);
    digitalWrite(PIN_BTN_SEQ, HIGH);
    digitalWrite(PIN_SW_SEQ,  HIGH);

    // set up outputs, tie low
    pinMode(PIN_OUT_0,        OUTPUT);
    pinMode(PIN_OUT_1,        OUTPUT);
    pinMode(PIN_OUT_2,        OUTPUT);
    pinMode(PIN_OUT_3,        OUTPUT);
    pinMode(PIN_OUT_4,        OUTPUT);
    pinMode(PIN_OUT_5,        OUTPUT);
    pinMode(PIN_OUT_6,        OUTPUT);
    pinMode(PIN_OUT_7,        OUTPUT);
    pinMode(PIN_STATUS,       OUTPUT);
    digitalWrite(PIN_OUT_0,   out0);
    digitalWrite(PIN_OUT_1,   out1);
    digitalWrite(PIN_OUT_2,   out2);
    digitalWrite(PIN_OUT_3,   out3);
    digitalWrite(PIN_OUT_4,   out4);
    digitalWrite(PIN_OUT_5,   out5);
    digitalWrite(PIN_OUT_6,   out6);
    digitalWrite(PIN_OUT_7,   out7);
    digitalWrite(PIN_STATUS,  outStatus);
    
    btnOn = true;
    btnSeq = false;
    swSeq = false;
  
}

void loop() {
  
  
    currentTime = micros();
    deltaTime = currentTime - previousTime;
    
    // task scheduling @ 10KHz
    if (deltaTime >= 100) {
        frameCounter++;
        
        // first, process 10KHz tasks
        process10KHz();
        
        if (frameCounter % TASK_100HZ == 0) {
            G_Dt = (currentTime - hundredHZpreviousTime) / 1000000.0;
            hundredHZpreviousTime = currentTime;
            previousTime = currentTime;
            
            process100Hz();
        } // 100Hz task loop
        
        /*
        if (frameCounter % TASK_10HZ == 0) {
        //G_Dt = (currentTime - tenHZpreviousTime) / 1000000.0;
        //tenHZpreviousTime = currentTime;
        
        process10Hz();
        } // 10Hz task loop
        
        if (frameCounter % TASK_1HZ == 0) {
        //G_Dt = (currentTime - oneHZpreviousTime) / 1000000.0;
        //oneHZpreviousTime = currentTime;
        
        process1Hz();
        } // 1Hz task loop
        */
        
    }
    
    if (frameCounter >= 10000) {
        frameCounter = 0;
    }
}

#endif//_SIGNALGENERATOR_
