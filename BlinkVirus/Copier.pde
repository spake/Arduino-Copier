/*
Arduino Copier - An arduino sketch that can upload sketches to other boards.
Copyright (C) 2010 George Caley.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

/*
This modification of the BlinkSync script is able to self-replicate!
This means that you don't have to compile and pass hex codes through Python scripts
or anything of the like.
The only thing you have to do is set the sketchLength variable in the Copier tab.
Just keep verifying the sketch and updating the sketchLength variable with Binary Sketch Length
the Arduino IDE displays until they're the same.
*/

#include <avr/pgmspace.h>

// the length of the sketch (duh)
int sketchLength = 5064;

// change this to whatever takes your fancy
// it should be connected to the Reset pin on the target board
int resetPin = 7;

// RX and TX should be connected to TX and RX on the target board, respectively.
// If the target board is already powered, then just connect their two
// GND pins together, otherwise connect their +5V pins together as well

int began = 0, groove = 50, i, j, start, end, address, laddress, haddress, error = 0, a, b, c, d, e, f, buff[128], buffLength, k, readBuff[16], preBuff, readBuffLength;

// Reads bytes until there's nothing left to read
// Then sticks 'em in readBuff, and sets readBuffLength
void readBytes() {
  readBuffLength = 0;
  while (Serial.available() > 0) {
    preBuff = Serial.read();
    // this if statement is necessary because for some reason, the target
    // board replies with 0xFC instead of 0x10
    // i've got no idea whether it's an error code, but simply substituting
    // 0xFC for 0x10 in the readBuff seems to do the trick
    if (preBuff == 0xFC) {
      preBuff = 0x10;
    }
    readBuff[readBuffLength] = preBuff;
    readBuffLength++;
  }
}

// Read bytes until there's nothing left to read
// The only difference to the above function is that
// this one doesn't substitute 0xFC for 0x10
void readBytess() {
  readBuffLength = 0;
  while (Serial.available() > 0) {
    readBuff[readBuffLength] = Serial.read();
    readBuffLength++;
  }
}

int copier() {
  if (!began) {
    Serial.begin(57600);
    pinMode(resetPin, OUTPUT);
    began = 1;
  }
  
  // Reset the target board
  digitalWrite(resetPin, LOW);
  delay(100);
  digitalWrite(resetPin, HIGH);
  delay(100);
  
  // Get in sync with the AVR
  for (i = 0; i < 25; i++) {
    Serial.print(0x30, BYTE); // STK_GET_SYNC
    Serial.print(0x20, BYTE); // STK_CRC_EOP
    delay(groove);
  }
                  
  readBytes();
  // We expect to receive 0x14 (STK_INSYNC) and 0x10 (STK_OK)
  // Every response must start with 0x14 and end with 0x10, otherwise
  // something's wrong
  if (readBuffLength < 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
    return 0;
  }
  
  Serial.flush();
  
  // Set the programming parameters
  Serial.print(0x42, BYTE);
  Serial.print(0x86, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x01, BYTE);
  Serial.print(0x01, BYTE);
  Serial.print(0x01, BYTE);
  Serial.print(0x01, BYTE);
  Serial.print(0x03, BYTE);
  Serial.print(0xff, BYTE);
  Serial.print(0xff, BYTE);
  Serial.print(0xff, BYTE);
  Serial.print(0xff, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x80, BYTE);
  Serial.print(0x04, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x80, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x20, BYTE);
  delay(groove);
  
  readBytes();
  if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
    return 0;
  }
  
  // Set the extended programming parameters
  Serial.print(0x45, BYTE);
  Serial.print(0x05, BYTE);
  Serial.print(0x04, BYTE);
  Serial.print(0xd7, BYTE);
  Serial.print(0xc2, BYTE);
  Serial.print(0x00, BYTE);
  Serial.print(0x20, BYTE);
  delay(groove);
  
  readBytes();
  if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
    return 0;
  }
  
  // Enter programming mode
  Serial.print(0x50, BYTE);
  Serial.print(0x20, BYTE);
  delay(groove);
  
  readBytes();
  if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
    return 0;
  }
  
  // Now comes the interesting part
  // We put blocks of data from our Arduino's flash and into buff, ready to write
  // to the target Arduino's flash
  // We only write in blocks of 128 or less bytes
  
  address = 0;
  for (i = 0; i < sketchLength; i += 128) {
    start = i;
    end = i + 127;
    if (sketchLength <= end) {
      end = sketchLength - 1;
    }
    buffLength = end - start + 1;
    for (j = 0; j < buffLength; j++) {
      buff[j] = pgm_read_byte(i+j);
    }
    // The buffer is now filled with the appropriate bytes
    
    // Set the address of the avr's flash memory to write to
    haddress = address / 256;
    laddress = address % 256;
    address += 64; // For the next iteration
    Serial.print(0x55, BYTE);
    Serial.print(laddress, BYTE);
    Serial.print(haddress, BYTE);
    Serial.print(0x20, BYTE);
    delay(groove);
    
    readBytes();
    if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
      return 0;
    }
    
    // Write the block
    Serial.print(0x64, BYTE);
    Serial.print(0x00, BYTE);
    Serial.print(buffLength, BYTE);
    Serial.print(0x46, BYTE);
    for (j = 0; j < buffLength; j++) {
      Serial.print(buff[j], BYTE);
    }
    Serial.print(0x20, BYTE);
    delay(groove);
    
    readBytes();
    if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
      return 0;
    }
  }
  
  // Leave programming mode
  Serial.print(0x51, BYTE);
  Serial.print(0x20, BYTE);
  delay(groove);
  readBytes();
  if (readBuffLength != 2 || readBuff[0] != 0x14 || readBuff[1] != 0x10) {
    return 0;
  }
  
  // If we've reached here, then all is well
  // But please note: no sketch verification is done by the Copier sketch!
  return 1;
}

#endif
