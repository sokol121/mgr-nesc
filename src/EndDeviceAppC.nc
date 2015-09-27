configuration EndDeviceAppC {

}
implementation {

	// general components
	components EndDeviceC as App;
	components MainC, LedsC;
	components new TimerMilliC() as sensorReadingTimer;
	components new TimerMilliC() as routingFinderTimer;
	components new TimerMilliC() as taskTimer; 

	App.Boot->MainC;
	App.Leds->LedsC;
	App.Timer->sensorReadingTimer;

	// for writing into serial port
	components SerialPrintfC;

	//sensors
	components new SensirionSht11C();
	components new Intersema5534C();
	components new Taos2550C();
	components new Accel202C();
	
	//App sensor conections
	App.Temperature->SensirionSht11C.Temperature;
	App.Humidity->SensirionSht11C.Humidity;
	App.Intersema -> Intersema5534C.Intersema;
	App.X_Axis -> Accel202C.X_Axis;
	App.Y_Axis -> Accel202C.Y_Axis;
	App.VisibleLight -> Taos2550C.VisibleLight;
	App.InfraredLight -> Taos2550C.InfraredLight;

  	components CollectionC as Collector;  // Collection layer
  	components new CollectionSenderC(AM_MOTEMSG); // Sends multihop RF
   	components ActiveMessageC;                         // AM layer
    
	components SerialActiveMessageC;                   // Serial messaging
    components new SerialAMSenderC(AM_MOTEMSG);   // Sends to the serial port

  App.RadioControl -> ActiveMessageC;
  App.SerialControl -> SerialActiveMessageC;
  App.RoutingControl -> Collector;

  App.Send -> CollectionSenderC;
  App.SerialSend -> SerialAMSenderC.AMSend;
  App.Receive -> Collector.Receive[AM_MOTEMSG];
  App.RootControl -> Collector;

  components new PoolC(message_t, 10) as UARTMessagePoolP,
    new QueueC(message_t*, 10) as UARTQueueP;

  App.UARTMessagePool -> UARTMessagePoolP;
  App.UARTQueue -> UARTQueueP;

	// radio communication
//	components ActiveMessageC;
//	components new AMSenderC(AM_MOTEMSG);
//	components new AMSenderC(AM_ROUTEMSG) as RouteSender;	
//	components new AMReceiverC(AM_MOTEMSG);
//	components new AMReceiverC(AM_ROUTEMSG)as RouteReceiver;
//	
//
//	App.Packet->AMSenderC;
//	App.AMPacket->AMSenderC;
//	App.AMSend->AMSenderC;
//	App.RouteSender->RouteSender;
//	App.AMControl->ActiveMessageC;
//	App.Receive->AMReceiverC;
//	App.RouteReceiver->RouteReceiver;
}