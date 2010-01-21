#define COPY

int led = 13;
int wait = 500;
int master = -1;
int syncWait = 2000;
int r;

#ifdef COPY
int trigger = 2;
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
    copier();
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
