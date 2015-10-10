configuration EndDeviceAppC {

}
implementation {

	// general components
	components EndDeviceC as App;
	components MainC, LedsC;
	components new TimerMilliC() as sensorReadingTimer;
	
	App.Boot->MainC;
	App.Leds->LedsC;
	App.Timer->sensorReadingTimer;

	// print lib
	components SerialPrintfC;

	//sensors components
	components new SensirionSht11C();
	components new Intersema5534C();
	components new Taos2550C();
	components new Accel202C();

	//App-sensor components connections
	App.Temperature->SensirionSht11C.Temperature;
	App.Humidity->SensirionSht11C.Humidity;
	App.Intersema->Intersema5534C.Intersema;
	App.X_Axis->Accel202C.X_Axis;
	App.Y_Axis->Accel202C.Y_Axis;
	App.VisibleLight->Taos2550C.VisibleLight;
	App.InfraredLight->Taos2550C.InfraredLight;
	
	//radio components
	components CollectionC as Collector; // Collection layer
	components new CollectionSenderC(AM_MOTEMSG); // Sends multihop RF
	components ActiveMessageC; // AM layer 
	
	//serial port writers components
	components SerialActiveMessageC; // Serial messaging
	components new SerialAMSenderC(AM_MOTEMSG); // Sends to the serial port 
	
	
	App.RadioControl->ActiveMessageC;
	App.RoutingControl->Collector;
	App.Send->CollectionSenderC;
	App.Receive->Collector.Receive[AM_MOTEMSG];
	App.RootControl->Collector;
	
	App.SerialControl->SerialActiveMessageC;
	App.SerialSend->SerialAMSenderC.AMSend;
	

	//poll and queue to carry messages revi
	components	new PoolC(message_t, 10) as UARTMessagePoolP,
				new QueueC(message_t *, 10) as UARTQueueP;
	
	App.UARTMessagePool->UARTMessagePoolP;
	App.UARTQueue->UARTQueueP;

}