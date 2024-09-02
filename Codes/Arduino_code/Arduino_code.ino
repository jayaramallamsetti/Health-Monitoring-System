#include <WiFi.h> 
#include <ESPAsyncWebServer.h> 
 #include <Wire.h>
#include "MAX30100_PulseOximeter.h"
#define REPORTING_PERIOD_MS     1000

uint32_t tsLastReport = 0;
#define TCA_ADDRESS 0x70

const char *ssid = "GK"; 
const char *password = "87654321"; 
 PulseOximeter vataSensor;  // MAX30100 sensor named "Vata"
PulseOximeter pittaSensor; 
PulseOximeter kaphaSensor;
void onBeatDetected()
{
//Serial.println("Beat!");
}
AsyncWebServer server(80); 
int sensorValue1 = 0; 
int sensorValue2 = 0; 
int sensorValue3 = 0; 
unsigned long lastUpdateTime = 0; 
const unsigned long updateInterval = 300;   
 
void setup() { 
  Serial.begin(115200); 
 
  // Connect to Wi-Fi 
  WiFi.begin(ssid, password); 
  while (WiFi.status() != WL_CONNECTED) { 
    delay(300); 
    Serial.println("Connecting to WiFi..."); 
  } 
  Serial.println("Connected to WiFi"); 
 
  // Print the IP address to Serial Monitor 
  Serial.print("IP Address: "); 
  Serial.println(WiFi.localIP()); 
  
  Serial.println("Initializing...");
  Wire.begin();

  // Select the TCA9548A multiplexer channel for "Vata"
  Wire.beginTransmission(TCA_ADDRESS);
  Wire.write(1 << 2); // Enable channel 0 for "Vata"
  Wire.endTransmission();

  // Initialize Vata sensor
  if (!vataSensor.begin())
   {
        Serial.println("FAILED");
        for(;;);
    } else {
        Serial.println("SUCCESS");
    }
 vataSensor.setOnBeatDetectedCallback(onBeatDetected);




  // Select the TCA9548A multiplexer channel for "Vata"
  Wire.beginTransmission(TCA_ADDRESS);
  Wire.write(1 << 1); // Enable channel 0 for "Vata"
  Wire.endTransmission();

  // Initialize Vata sensor
  if (!pittaSensor.begin())
   {
      Serial.println("FAILED");
        for(;;);
    } else {
      Serial.println("SUCCESS");
    }
 pittaSensor.setOnBeatDetectedCallback(onBeatDetected);

 
  // Select the TCA9548A multiplexer channel for "Vata"
  Wire.beginTransmission(TCA_ADDRESS);
  Wire.write(1 << 1); // Enable channel 0 for "Vata"
  Wire.endTransmission();

  // Initialize Vata sensor
  if (!kaphaSensor.begin())
   {
        Serial.println("FAILED");
        for(;;);
    } else {
        Serial.println("SUCCESS");
    }
  kaphaSensor.setOnBeatDetectedCallback(onBeatDetected);


  // Define server routes 
  server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) { 
    // Increment the counter for each request 
 sensorValue1 += 1; 
 sensorValue2 += 1 ; 
 sensorValue3 += 1; 
    if(sensorValue1>150|| sensorValue2>150 || sensorValue3>150  ) 
    { 
      sensorValue1=0; 
      sensorValue2=0; 
      sensorValue3=0; 
    } 
   
    String json = String(0) + ","+String(sensorValue1) + "," +String(sensorValue2) + "," +String(sensorValue3) ; 
    AsyncWebServerResponse *response = request->beginResponse(200, "application/json", json); 
 
    // Add the Connection: keep-alive header 
    response->addHeader("Connection", "keep-alive"); 
 
    // Send the response 
    request->send(response); 
     
  }); 
 
  // Start server 
  server.begin(); 
} 
 
void loop() { 
     vataSensor.update();
    pittaSensor.update();
    kaphaSensor.update();
    if (millis() - tsLastReport > REPORTING_PERIOD_MS) {
        ///Serial.print("Heart rate vata:");
            Serial.print(vataSensor.getHeartRate());
            Serial.print(",");
            Serial.print(pittaSensor.getHeartRate());
            Serial.print(",");
            Serial.print(kaphaSensor.getHeartRate());
            Serial.println("");

        //Serial.print("Heart rate pitta:");
        //Serial.println(pittaSensor.getHeartRate());
        //Serial.print("Heart rate kapha:");
        //Serial.println(kaphaSensor.getHeartRate());
        tsLastReport = millis();
    }

  // The server will automatically handle incoming requests 
  delay(300);  // Delay to simulate changing values 
}