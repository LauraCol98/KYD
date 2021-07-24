// Imports libraries
#include "printf.h"
#include "Timer.h"
#include "KYDMessage.h"
// Define constants 
#define memoryLength 50

module KYDC {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as timer; // as Millitimer?
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {
    // Variables
    message_t packet;
    bool isLocked;
    uint8_t index;
    uint8_t counter = 0;
    // Stores the last received IDs [50]
    uint8_t received_id [memoryLength];
  
    // BOOT event handler
    event void Boot.booted() {
        // After the mote boot phase starts the radio module
  	    dbg("log", "Mote %u: mote booted.\n", TOS_NODE_ID);
        call AMControl.start();}

    // Event triggered by the radio startup
    event void AMControl.startDone(error_t err) {
  	    dbg("log", "Mote %u: radio module is now active\n", TOS_NODE_ID);
        //After the radio module has been activated, creates a 500ms timer
        call timer.startPeriodic(500);}

    // TIMER_FIRED : Event triggered by the firing of the timer
    event void timer.fired() {
        dbg("log", "Mote %u: timer has been fired!\n", TOS_NODE_ID);
        if (isLocked) 
            return;
        else {
            radioMessage* message = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
            if (message == NULL) {
            	dbg("log", "Mote %u: message creation failed. Nothing will be sent\n", TOS_NODE_ID);
                return;}
      
        // Broadcast the mote ID
        message->identifier = TOS_NODE_ID;
        if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radioMessage)) == SUCCESS) {
      	    dbg("log", "Mote %u: Message broadcasted successfully!\n", TOS_NODE_ID);
            isLocked = TRUE;}
        }
    }

    // Saves the mote ID
    void saveID(uint8_t ID) {
        // Don't save the same mote ID twice if it has been received multiple times in a row
        if (counter > 0 && received_id[counter - 1] != ID) {
            if (counter < memoryLength) {
      	        dbg("log", "Mote %u: saving ID: %u in memory...\n", TOS_NODE_ID, ID);
                received_id[counter] = ID;
                dbg("log", "Mote %u: ID %u has been stored successfully!\n", TOS_NODE_ID, ID);
                counter++;} 
            else {
                //If the array is full, shift-left the cells of the array by one
                dbg("log", "Mote %u: Memory is full, left-shift FIFO.\n", TOS_NODE_ID);
                    for (index = 0; index < memoryLength - 1; index++) {
                        received_id[index] = received_id[index + 1];
                    }
                dbg("log", "Mote %u: shift operation completed.\n", TOS_NODE_ID);
                // Add the last received ID
                dbg("log", "Mote %u: saving ID: %u in memory...\n", TOS_NODE_ID, ID);
                received_id[memoryLength - 1] = ID;
                dbg("log", "Mote %u: ID %u has been stored successfully!\n", TOS_NODE_ID, ID);
            }
        return;}
        else 
    	    dbg("log", "Mote %u: ID already present in memory at the last position. ID : %u\n", TOS_NODE_ID, ID);
    
        if (counter == 0) {
            dbg("log", "Mote %u: no IDs saved. Storing the first one in memory... ID: %u\n", TOS_NODE_ID, ID);
        received_id[counter] = ID;
        dbg("log", "Mote %u: first ID stored. ID: %u\n", TOS_NODE_ID, ID);
        counter++;
        return;
        }
    } 
    
    // Defines the behaviour when a mote receives a message
    event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
        if (len != sizeof(radioMessage)) {
            dbg("log", "Mote %u: bad packet detected\n", TOS_NODE_ID);
            return bufPtr;
        }
        else {
            radioMessage* message = (radioMessage*)payload;
            dbg("log", "Mote %u: received packet from the mote %u.\n", TOS_NODE_ID, message->identifier);
            // Saves the received ID
            dbg("log", "Mote %u: Saving the received ID... ID : %u \n", TOS_NODE_ID, message->identifier);
            saveID(message->identifier);
      
            // Forwards the received ID to NodeRed
            dbg("log", "Mote %u: Forwarding message to node-RED... ID: %u\n", TOS_NODE_ID, message->identifier);
            printf("%u\n", message->identifier);
            dbg("log", "Mote %u: all done! ID: %u\n", TOS_NODE_ID, message->identifier);
            printfflush();
            return bufPtr;
        }
    }
  
    // Free the radio when the sending phase ends
    event void AMSend.sendDone(message_t* bufPtr, error_t error) {
        if (&packet == bufPtr) 
            isLocked = FALSE;
    }

    event void AMControl.stopDone(error_t err) {}
}
