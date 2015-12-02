/* Simple bit banged SPI to communicate with the
 * 25LC640A 64K SPI Bus Serial EEPROM
 * Purpose of code is to use as demonstration
 * signaling for logic analyzer project - ECE 544.
 */

#include <stdio.h>

//Instruction codes for 25LC640A
const byte READ  = 0x03;
const byte WRITE = 0x02;
const byte WRDI  = 0x04; // Reset write enable latch (disable write)
const byte WREN  = 0x06; // Set write enable latch (enable write)
const byte RDSR  = 0x05; // Read STATUS register
const byte WRSR  = 0x01; // Write STATUS register

//Pin assignments
const int CS_BAR = 13;  // Low active chip select
const int SCLK   = 12;  // SPI clk
const int SI     = 11;  // Slave In
const int SO     = 10;  // Slave Out

// Char buffer for serial prints
char serial_buff[65];
unsigned int addressCounter;
byte dataCounter;
byte dataBack;

const unsigned int LOOP_DELAY = 500; //msec

void setup() {
  Serial.begin(9600);
  
  pinMode(CS_BAR, OUTPUT);
  pinMode(SCLK,   OUTPUT);
  pinMode(SI,     OUTPUT);
  pinMode(SO,     INPUT );
  
  digitalWrite(CS_BAR,HIGH);
  digitalWrite(SCLK,   LOW);
  
  digitalWrite(CS_BAR, LOW);
  shiftByteOut(WRSR);
  shiftByteOut(0x00);
  digitalWrite(CS_BAR, HIGH);
}

void loop() {
//  sprintf(serial_buff, "Writing to address: %d, Data: %d", addressCounter, dataCounter);
//  Serial.println(serial_buff);
  doWrite(addressCounter,dataCounter*2);
  doRead(addressCounter);
  //sprintf(serial_buff, "Got data back from address %d, Data is %d", addressCounter, dataBack);
//  Serial.println(serial_buff);
  readStatus();
  addressCounter++;
  dataCounter++;
//  sprintf(serial_buff, "Status: %d", sreg);
//  Serial.println(serial_buff);
//  delay(LOOP_DELAY);
}

// toggle sclk high and low -
// assumes normal state is low
void toggleSCK(void) {
  int i;
  digitalWrite(SCLK, HIGH);
//  for(i = 0; i < 10000; i++);
  digitalWrite(SCLK, LOW);
}

// Shifts a byte of data out
// MSB first.
// - puts each bit onto the SI pin
// - toggles SCK
// Does not do anything with CS_BAR
void shiftByteOut(byte data) {
  int i;
  for (i = 7; i >= 0; i--) {
    byte value = (data >> i) & 0x01;
    digitalWrite(SI, value);
    toggleSCK();
  }
}

//shift in a byte of data MSB first
byte shiftByteIn(void) {
  byte dataIn = 0x00;
  int i;
  for (i = 7; i >= 0; i--) {
     digitalWrite(SCLK, HIGH);
     u8 value = digitalRead(SO);
     digitalWrite(SCLK, LOW);
     dataIn |= (value << i);
  }
  return dataIn;
}

//Simple single byte read - the
//eeprom chip is capabale of doing
//more complex reads beyond a single byte
//by auto-incrementing the address pointer
byte doRead(unsigned int address) {
   digitalWrite(CS_BAR, LOW); // Assert chip select
   shiftByteOut(READ);
   shiftOutAddress(address);
   byte data = shiftByteIn();
   digitalWrite(CS_BAR,HIGH);
   return data;
}

//single byte write - the eeprom is capable of
//writing up to 32 bytes in a single write cycle.
//since there is a 5 ms delay between writes,
//this would be more efficient, but this
//is for demonstration purposes only.
void doWrite(unsigned int address, byte data) {
  enableWrite();
  digitalWrite(CS_BAR, LOW);
  shiftByteOut(WRITE);
  shiftOutAddress(address);
  shiftByteOut(data);
  digitalWrite(CS_BAR, HIGH);
  delay(5); // Necessary delay time between write cycles
}

//shift out a 16 bit address
void shiftOutAddress(unsigned int address) {
  byte upperByte = address >> 8;
  byte lowerByte = address & 0x00FF;
  shiftByteOut(upperByte);     // Upper byte
  shiftByteOut(lowerByte);     // Lower byte  
}

//set the write enable latch
void enableWrite() {
  digitalWrite(CS_BAR, LOW);
  shiftByteOut(WREN);
  digitalWrite(CS_BAR, HIGH);
}

// read the status register
byte readStatus() {
  digitalWrite(CS_BAR, LOW);
  shiftByteOut(RDSR);
  byte sReg = shiftByteIn();
  digitalWrite(CS_BAR, HIGH);
  return sReg;
}

