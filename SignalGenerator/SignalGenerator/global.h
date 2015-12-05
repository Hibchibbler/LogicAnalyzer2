
#ifndef _GLOBAL_H_
#define _GLOBAL_H_

// IO
// inputs
#define PIN_BTN_ON  2
#define PIN_BTN_SEQ 3
#define PIN_SW_SEQ  4
boolean btnOn           = false;
boolean btnSeq          = false;
boolean swSeq           = false; 
byte    btnOnCount      = 0;
byte    btnOnCountMax   = 0;
byte    btnSeqCount     = 0;
byte    btnSeqCountMax  = 5;
byte    swSeqCount      = 5;
byte    swSeqCountMax   = 5;
// outputs
// test signals
#define PIN_OUT_0   5
#define PIN_OUT_1   6
#define PIN_OUT_2   7
#define PIN_OUT_3   8
#define PIN_OUT_4   9
#define PIN_OUT_5  10
#define PIN_OUT_6  11
#define PIN_OUT_7  12
boolean out0 = false;
boolean out1 = false;
boolean out2 = false;
boolean out3 = false;
boolean out4 = false;
boolean out5 = false;
boolean out6 = false;
boolean out7 = false;
// status indicator
#define PIN_STATUS  13
boolean outStatus = false;


// loop timing vars
#define TASK_1000HZ 10
#define TASK_500HZ  20
#define TASK_250HZ  40
#define TASK_100HZ 100
#define TASK_50HZ  200
#define TASK_10HZ 1000
#define TASK_5HZ  2000
#define TASK_2HZ  5000
#define TASK_1HZ 10000
float   G_Dt                   = 0.002;
long    currentTime;
long    deltaTime              = 0;
long    previousTime           = 0;
long    hundredHZpreviousTime  = 0;
long    tenHZpreviousTime      = 0;
long    oneHZpreviousTime      = 0;
long    frameCounter           = 0;

// state machine
#define NUM_STATES  4
#define SEQ_0       0
#define SEQ_1       1
#define SEQ_2       2
#define SEQ_3       3
#define SEQ_4       4
#define SEQ_5       5
#define SEQ_6       6
#define SEQ_7       7
#define SEQ_8       8
#define SEQ_9       9
int     state               = SEQ_0;
int     stateNext           = SEQ_0;
boolean stateNextAllowed    = false;
int     stateCounter        = 0;
int     stateCounterMax     = 50; // half a second doing each sample type (updates at 100Hz)

boolean outputSignals       = true;
boolean outputSignalToggleAllowed = true;


#endif//_GLOBAL_H_

