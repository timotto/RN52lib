#include <RN52.h>

// RN-52 specific PINs
#define BT_GPIO2    2
#define BT_GPIO9    4

// extend the RN52driver to implement callbacks and hardware interface
class RNimpl : public RN52::RN52driver {
  // called by RN52lib when the connected Bluetooth devices
  // uses a profile
  void onProfileChange(BtProfile profile, bool connected);
public:
  // this is used by RN52lib to send data to the RN52 module
  // the implementation of this method needs to write to the 
  // connected serial port
  void toUART(const char* c, int len);
  // this method is called by RN52lib when data arrives via
  // the SPP profile
  void fromSPP(const char* c, int len);
  // this method is called by RN52lib whenever it needs to
  // switch between SPP and command mode
  void setMode(Mode mode);
  // GPIO2 of RN52 is toggled on state change, eg. a Bluetooth
  // devices connects
  void onGPIO2();
};

// some state variables not used in this sketch at all
bool playing = true;
bool bt_iap = false;
bool bt_spp = false;
bool bt_a2dp = false;
bool bt_hfp = false;

RNimpl rn52;

void setup(){
  pinMode(BT_GPIO9, OUTPUT);
  digitalWrite(BT_GPIO9, HIGH);
  pinMode(BT_GPIO2, INPUT);
  digitalWrite(BT_GPIO2, LOW);
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);
  rn52.onGPIO2();
  bt_visible();
}

uint32_t lastHi2Lo = 0;
uint32_t triggerIn = 0;
int gpio2 = 0;
void loop() {

  // feed the RN52lib with data from the RN52 bluetooth module
  while (Serial.available()) {
    char c = Serial.read();
    rn52.fromUART(c);
  }

  // clumsy de-bouncer for RN52 GPIO2 state change indications
  bool stateChanged = false;
  int n = digitalRead(BT_GPIO2);
  if (n != gpio2) {
    uint32_t now = millis();
    gpio2 = n;
    if (n) {
      // pin went hi
      if (now <= (lastHi2Lo+100)) {
        // last hi to lo transision is less than 150ms, this is a state change
        
        stateChanged = true;
        triggerIn = now + 100;
        if(!triggerIn)triggerIn=1;
      }
    } else {
      // pin went lo
      lastHi2Lo = now;
    }
  }
  if (triggerIn) {
    uint32_t now = millis();
    if(now >= triggerIn){
      triggerIn = 0;
      rn52.onGPIO2();
    }
  }
}

// implementation of the hardware interface
void RNimpl::toUART(const char* c, int len){
  for(int i=0;i<len;i++)
    Serial.write(c[i]);
};

// put your implementation here that handles SPP data
void RNimpl::fromSPP(const char* c, int len){
  // bytes received from phone via SPP
  
  // to send bytes back to the phone call rn52.toSPP
};


void RNimpl::setMode(Mode mode){
  if (mode == COMMAND) {
    digitalWrite(BT_GPIO9, LOW);
  } else if (mode == DATA) {
    digitalWrite(BT_GPIO9, HIGH);
  }
};

const char *CMD_QUERY = "Q\r";
void RNimpl::onGPIO2() {
  queueCommand(CMD_QUERY);
}

void RNimpl::onProfileChange(BtProfile profile, bool connected) {
  switch(profile) {
    case A2DP:bt_a2dp = connected;
      if (connected && playing)bt_play();
      break;
    case SPP:bt_spp = connected;break;
    case IAP:bt_iap = connected;break;
    case HFP:bt_hfp = connected;break;
  }
}

// examples of how to use the AVRCP methods
void bt_play() {
  rn52.sendAVCRP(RN52::RN52driver::PLAY);
}

void bt_pause() {
  rn52.sendAVCRP(RN52::RN52driver::PAUSE);
}

void bt_prev() {
  rn52.sendAVCRP(RN52::RN52driver::PREV);
}

void bt_next() {
  rn52.sendAVCRP(RN52::RN52driver::NEXT);
}

void bt_visible() {
  rn52.visible(true);
}

void bt_invisible() {
  rn52.visible(false);
}

void bt_reconnect() {
  rn52.reconnectLast();
}

void bt_disconnect() {
  rn52.disconnect();
}

