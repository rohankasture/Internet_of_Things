int pirSensor = D0;
int led1 = D1;
int roomTrigger = -1;

void setup() {
    // pinMode(pirValue, INPUT);
    pinMode(led1, OUTPUT);
}

void loop() {
    roomTrigger = digitalRead(pirSensor);
    if (roomTrigger) {
        digitalWrite(led1, HIGH);
        Particle.publish("occupancy_of_room", "Occupied", 60, PRIVATE);
        
    } else {
        digitalWrite(led1, LOW);
        Particle.publish("occupancy_of_room", "Free", 60, PRIVATE);
    
    }
    delay(10000);
}

          

