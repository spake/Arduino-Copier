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

// if COPY gets #defined, then the Copier code and the code
// for the upload button are included with the BlinkSync sketch
#define COPY

int led = 13;
int wait = 500;
int master = -1;
int syncWait = 2000;
int r;

#ifdef COPY
int trigger = 2; // the upload button
#endif

void setup() {
  pinMode(led, OUTPUT);
  #ifdef COPY
  pinMode(trigger, INPUT);
  digitalWrite(trigger, HIGH);
  #endif
  Serial.begin(57600);
}

void loop() {
  #ifdef COPY
  if (digitalRead(trigger) == LOW) {
    digitalWrite(led, HIGH);
    while(digitalRead(trigger) == LOW);
    digitalWrite(led, LOW);
    copier(); // this triggers the copy
  }
  #endif
  
  if (master == -1) {
    // we don't know whether we're a master or not
    // wait for x ms
    delay(syncWait);
    // have we got anything?
    if (Serial.available() > 0) {
      // yes we do!
      // that means we're nothing but a slave :(
      // flush this away
      Serial.flush();
      master = 0;
    } else {
      // nothing received
      // we are the masters of the serial port
      master = 1;
    }
  }
  
  if (master) {
    // complete one blink cycle
    // also sending out sync signals to the slave
    Serial.print(0xFF, BYTE);
    digitalWrite(led, HIGH);
    delay(500);
    digitalWrite(led, LOW);
    Serial.print(0xFE, BYTE);
    delay(500);
  } else {
    // we're a slave
    // wait for the sync signals from the master
    if (Serial.available() > 0) {
      r = Serial.read();
      if (r == 0xFF) {
        digitalWrite(led, HIGH);
      } else if (r == 0xFE) {
        digitalWrite(led, LOW);
      }
    }
  }
}
