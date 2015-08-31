configuration EndDeviceAppC {

}
implementation {

	// general components
	components EndDeviceC as App;
	components MainC, LedsC;
	components new TimerMilliC();

	App.Boot->MainC;
	App.Leds->LedsC;
	App.Timer->TimerMilliC;

	// for writing into serial port
	components SerialPrintfC;

	//sensors
	components new SensirionSht11C();
	components new Intersema5534C();
	components new Taos2550C();
	components new Accel202C();
	
	//app sensor conections
	App.Temperature->SensirionSht11C.Temperature;
	App.Humidity->SensirionSht11C.Humidity;
	App.Intersema -> Intersema5534C.Intersema;
	App.X_Axis -> Accel202C.X_Axis;
	App.Y_Axis -> Accel202C.Y_Axis;
	App.VisibleLight -> Taos2550C.VisibleLight;
	App.InfraredLight -> Taos2550C.InfraredLight;

	// radio communication
	components ActiveMessageC;
	components new AMSenderC(AM_MOTEMSG);
	components new AMReceiverC(AM_MOTEMSG);

	App.Packet->AMSenderC;
	App.AMPacket->AMSenderC;
	App.AMSend->AMSenderC;
	App.AMControl->ActiveMessageC;
	App.Receive->AMReceiverC;
}