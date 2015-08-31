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

		// Sth11 readers
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Humidity;		
		interface Read<uint16_t> as X_Axis;
		interface Read<uint16_t> as Y_Axis;
		interface Intersema;
		interface Read<uint8_t> as VisibleLight;
		interface Read<uint8_t> as InfraredLight;

		// radio communication
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
	}
}

implementation {

	uint16_t AccelX_data,AccelY_data,Temp_data,Hum_data,VisLight_data, InfraLight_data;
	int16_t Intersema_data[2];
	
	uint16_t temperatureValue;
	uint16_t humidityValue;
	
	bool radioBusy = FALSE;
	message_t pkt;
	error_t sendError;
	void report_problem() { call Leds.led0Toggle(); }
	void report_sent() { call Leds.led1Toggle(); }
	void report_received() { call Leds.led2Toggle(); }
  
	void sent() 
	{ 
				// creating the packet 
			if(radioBusy == FALSE) {
				motemsg_t * msg = call Packet.getPayload(&pkt, sizeof(motemsg_t));
				msg->	nodeId 		= TOS_NODE_ID;
				msg->	tempVal 	= temperatureValue;
				msg->	humVal 		= humidityValue;
				msg->	AccelX_data = AccelX_data;
				msg-> 	AccelY_data = AccelY_data;
				msg-> 	Intersema_data[0] = Intersema_data[0];
				msg-> 	Intersema_data[1] = Intersema_data[1];
				msg->	VisLight_data	= VisLight_data;
				msg->	InfLight_data 	= InfraLight_data;
				 

				// sending packet
				sendError = call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(motemsg_t));
				if(sendError == SUCCESS) {
					call Leds.led2Toggle();
					radioBusy = TRUE;
				} else {
					printf("Error sending msg, code: %d", sendError);
					call Leds.led0Toggle();					
				}
				sendError = 0;
			}

	}
		
	event void Boot.booted() {
		call AMControl.start();
	}

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
		sent();
		
	}
	

	
	event void Temperature.readDone(error_t result, uint16_t val) {
		if(result == SUCCESS) 
		{
			temperatureValue =  val;
		}
		else 
		{
			printf("Error reading light sensor.\r\n");
			call Leds.led0Toggle();
		}
	}
	
	event void Humidity.readDone(error_t result, uint16_t val){
		if(result == SUCCESS) 
		{
			humidityValue = 2.5 * (val / 4096.0) * 6250;
		}
		else 
		{
			printf("Error reading light sensor.\r\n");
			call Leds.led0Toggle();
		}
	}

	event void AMSend.sendDone(message_t * msg, error_t error) {
		if(msg == &pkt) {
			radioBusy = FALSE;
		}
	}

	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			call Timer.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t error){
		
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if(len == sizeof(motemsg_t)) { 
			motemsg_t* incomingPacket = (motemsg_t *) payload;
			call Leds.led1Toggle();
		}
		return msg;
	}



	event void Intersema.readDone(error_t error, int16_t *data){
		Intersema_data[0]=data[0];
		Intersema_data[1]=data[1];
	}


	event void X_Axis.readDone(error_t result, uint16_t val){
		AccelX_data = val;
	}

	event void Y_Axis.readDone(error_t result, uint16_t val){
		AccelY_data = val;
	}

	event void VisibleLight.readDone(error_t result, uint8_t val){
		VisLight_data = val;
	}

	event void InfraredLight.readDone(error_t result, uint8_t val){
		InfraLight_data = val;
	}
}