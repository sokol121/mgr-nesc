#include <Timer.h>
#include <stdio.h>
#include <string.h>
#include "MoteMsg.h"

module EndDeviceC {

	uses {

		// general
		interface Boot;
		interface Timer<TMilli>;
		interface Leds;
		
	    // Interfaces for initialization:
		interface SplitControl as RadioControl;
    	interface SplitControl as SerialControl;
    	interface StdControl as RoutingControl;
    
	    // Interfaces for communication, multihop and serial:
		interface Send;
		interface Receive;
		interface AMSend as SerialSend;
		interface CollectionPacket;
		interface RootControl;
		
        interface Queue<message_t *> as UARTQueue;
    	interface Pool<message_t> as UARTMessagePool;
    
    

		// Sensors readers intrfaces
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Humidity;		
		interface Read<uint16_t> as X_Axis;
		interface Read<uint16_t> as Y_Axis;
		interface Intersema;
		interface Read<uint8_t> as VisibleLight;
		interface Read<uint8_t> as InfraredLight;

	}
}

implementation {
	////////////////////////////////////////Sensors variables/////////////////////////////////////////////////////////
	uint16_t AccelX_data,AccelY_data,Temp_data,Hum_data,VisLight_data, InfraLight_data, temperatureValue,humidityValue;
	int16_t Intersema_data[2];
	/////////////////////////////////////////////Radio Values/////////////////////////////////////////////////////////
	bool radioBusy = FALSE;
	message_t pkt;
	//////////////////////////////////////////////Funcitons Templates/////////////////////////////////////////////////
	task void uartSendTask();
	/////////////////////////////////////////////Messages Functions///////////////////////////////////////////////////
	
	void fill_sensor_message(motemsg_t * msg){
		msg->	nodeId 		= TOS_NODE_ID;
		msg->	tempVal 	= temperatureValue;
		msg->	humVal 		= humidityValue;
		msg->	AccelX_data = AccelX_data;
		msg-> 	AccelY_data = AccelY_data;
		msg-> 	Intersema_data[0] = Intersema_data[0];
		msg-> 	Intersema_data[1] = Intersema_data[1];
		msg->	VisLight_data	= VisLight_data;
		msg->	InfLight_data 	= InfraLight_data;		
	}
	
	void start_sending_data(){
		printf("Start reading sensor\n");
		call Timer.startPeriodic(TIMER_PERIOD_MILLI);
	}
	////////////////////////////////////////////Led Functions/////////////////////////////////////////////////////////
	void report_problem() 	{ call Leds.led0Toggle(); }
	void report_send() 		{ call Leds.led1Toggle(); }
	void report_received() 	{ call Leds.led2Toggle(); }
	message_t sendbuf;
  	message_t uartbuf;
  	bool uartbusy=FALSE;
	
  /////////////////////////////////////Starting Events////////////////////
  	event void Boot.booted() {
	printf("Booted\n");
    if (call RadioControl.start() != SUCCESS)
      report_problem();
	}

	 event void RadioControl.startDone(error_t err) {
	    if (err != SUCCESS)
	      call RadioControl.start();
	    else {
	    	call RoutingControl.start();
	      	if (TOS_NODE_ID == 1){ 
	      		printf("I'm rooter\n\r");
				call RootControl.setRoot();
				 if (call SerialControl.start() != SUCCESS)
      				report_problem();
			}else
				start_sending_data();
	    }
  	}
	////////////////////////////////////////////////////////////////////////////
	void send() 
	{ 
		printf("Trying to send radioBusy:  %d \n\r ", radioBusy);
			if(radioBusy == FALSE) {
				motemsg_t * msg = call Send.getPayload(&pkt, sizeof(motemsg_t));
				printf("sending\n\r");
				fill_sensor_message(msg);				// sending packet
				if(call Send.send(&pkt, sizeof(motemsg_t)) == SUCCESS) {
					report_send();
					radioBusy = TRUE;
				} else {
					printf("Error while sending message\n\r");
					call Leds.led0Toggle(); call Leds.led2Toggle();	
				}
			}
	}
////////////////////Timer Fireds///////////////////////////////////////////
	event void Timer.fired() {
		if(call Temperature.read() != SUCCESS) {
			report_problem();
		}
		if(call Humidity.read() != SUCCESS) {
			report_problem();
		}
		if(call Intersema.read() != SUCCESS) {
			report_problem();
		}
		if(call X_Axis.read() != SUCCESS) {
			report_problem();
		}
		if(call Y_Axis.read() != SUCCESS) {
			report_problem();
		}
		if(call VisibleLight.read() != SUCCESS) {
			report_problem();
		}
		if(call InfraredLight.read() != SUCCESS) {
			report_problem();
		}
		send();
	}	
//////////////////sensors reading events///////////////////////////////////
		event void Temperature.readDone(error_t result, uint16_t val) {
		if(result == SUCCESS)		{
			temperatureValue =  val;
		}
		else {
			report_problem();
		}
	}
	
	event void Humidity.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			humidityValue = val;
		}
		else{
			report_problem();
		}
	}
	event void Intersema.readDone(error_t result, int16_t *data){
		if(result == SUCCESS){
			Intersema_data[0]=data[0];
			Intersema_data[1]=data[1];
		}
		else {
			report_problem();
		}
	}

	event void X_Axis.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){
			AccelX_data = val;
		}
		else{
			report_problem();
		}
	}

	event void Y_Axis.readDone(error_t result, uint16_t val){
		if(result == SUCCESS){ 
			AccelY_data = val;
		}
		else{
			report_problem();
		}
	}

	event void VisibleLight.readDone(error_t result, uint8_t val){
		if (result == SUCCESS){
			VisLight_data = val;
		}
		else{
			report_problem();
		}
	}

	event void InfraredLight.readDone(error_t result, uint8_t val){
		if (result == SUCCESS){	
			InfraLight_data = val;
		}
		else{
			report_problem();
		}
	}
/////////////////////////////////////////////done events/////////////////////////////////////////
	event void SerialControl.startDone(error_t error){}

	event void SerialControl.stopDone(error_t error){}

	/////////////////////////Message receiver////////////////////////////////////////////	
  //
  // Only the root will receive messages from this interface; its job
  // is to forward them to the serial uart for processing on the pc
  // connected to the sensor network.
  //
  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len) {

    motemsg_t* in = (motemsg_t*)payload;
    motemsg_t* out;
    
    if (uartbusy == FALSE) {
      out = (motemsg_t*)call SerialSend.getPayload(&uartbuf, sizeof(motemsg_t));
      if (len != sizeof(motemsg_t) || out == NULL) {
		return msg;
      }
      else {
		memcpy(out, in, sizeof(motemsg_t));
      }
      post uartSendTask();
    }else {
      // The UART is busy; queue up messages and service them when the
      // UART becomes free.
      message_t *newmsg = call UARTMessagePool.get();
      if (newmsg == NULL) {
        // drop the message on the floor if we run out of queue space.
        report_problem();
        return msg;
      }

      //Serial port busy, so enqueue.
      out = (motemsg_t*)call SerialSend.getPayload(newmsg, sizeof(motemsg_t));
      if (out == NULL) {
	return msg;
      }
      memcpy(out, in, sizeof(motemsg_t));

      if (call UARTQueue.enqueue(newmsg) != SUCCESS) {
        // drop the message on the floor and hang if we run out of
        // queue space without running out of queue space first (this
        // should not occur).
        call UARTMessagePool.put(newmsg);
        report_problem();
        return msg;
      }
    }

    return msg;
  }

  task void uartSendTask() {
    if (call SerialSend.send(0xffff, &uartbuf, sizeof(motemsg_t)) != SUCCESS) {
      report_problem();
    } else {
      uartbusy = TRUE;
    }
  }

	event void RadioControl.stopDone(error_t error){
	}

	event void Send.sendDone(message_t *msg, error_t error){
		printf("Send done\n\r");
		if (error != SUCCESS)
	      report_problem();
	    	radioBusy = FALSE;
	}


	event void SerialSend.sendDone(message_t *msg, error_t error){
		    uartbusy = FALSE;
    if (call UARTQueue.empty() == FALSE) {
      // We just finished a UART send, and the uart queue is
      // non-empty.  Let's start a new one.
      message_t *queuemsg = call UARTQueue.dequeue();
      if (queuemsg == NULL) {
        report_problem();
        return;
      }
      memcpy(&uartbuf, queuemsg, sizeof(message_t));
      if (call UARTMessagePool.put(queuemsg) != SUCCESS) {
        report_problem();
        return;
      }
      post uartSendTask();
    }
	}
}