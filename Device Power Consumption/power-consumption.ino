enum State { RED, BLUE, GREEN, CYAN, MAGENTA };
State state = RED;
TCPClient client;

void setup() {
    Serial.begin(9600);
    RGB.control(true);
// Register handler to handle clicking on the SETUP button
    System.on(button_click, buttonHandler);
    RGB.color(0,0,0);
}

void loop() {
//    uint16_t *sendBuf = NULL;
    RGB.brightness(64);
    switch(state) {
    case RED:
        // Waiting for the user to press the SETUP button. The setup button handler
        // will bump the state into STATE_CONNECT
        WiFi.on();
        RGB.color(255,0,0);
        
        break;

    case BLUE:
  
        // Ready to connect to the server via TCP
        WiFi.off();
        RGB.color(0,0,255);
        break;
    
    case GREEN:
        WiFi.off();
        RGB.brightness(255);
        RGB.color(255,255,255);
        break;
    
    case CYAN:
        WiFi.on();
        RGB.color(0,0,0);
        client.connect("iot.lukefahr.org", 16000);
        if (client.connected())
        {
            //IPAddress clientIP = client.remoteIP();
            RGB.color(0,255,255);
            // IPAddress equals whatever www.google.com resolves to
        }
        // delay(1000);
        client.write("ROHAN");
        client.stop();
        break;
    
    case MAGENTA:
        WiFi.off();
        System.sleep(SLEEP_MODE_DEEP, 20);
        RGB.color(255,0,255);
        break;
    }
}

// button handler for the SETUP button, used to toggle recording on and off
void buttonHandler(system_event_t event, int data) {
    switch(state) {
    case RED:
        state = BLUE;
        break;

    case BLUE:
    state = GREEN;
        break;
    
    case GREEN:
        state = CYAN;
        break;
    
    case CYAN:
        state = MAGENTA;
        break;
        
    case MAGENTA:
        state = RED;
        break;
    }
}
