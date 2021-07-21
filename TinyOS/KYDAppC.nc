// Imports the message structure
#include "KYDMessage.h"
// Imports printf library
#define CUSTOM_PRINTF
#include "printf.h"

// Wires the interfaces to the components
configuration KYDAppC{}
implementation {
    components MainC, KYDC as App;
    // Printf
    components PrintfC;
    components SerialStartC;
    // Radio
    components new AMSenderC(AM_RADIO_COUNT_MSG);
    components new AMReceiverC(AM_RADIO_COUNT_MSG);
    // Timers
    components new TimerMilliC();
    // Active message 
    components ActiveMessageC;

    // Interfaces
    App.Boot -> MainC.Boot;
    App.MilliTimer -> TimerMilliC;
    App.AMSend -> AMSenderC;
    App.Packet -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.AMControl -> ActiveMessageC;
}