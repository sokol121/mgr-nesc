#ifndef MOTEMSG_H
#define MOTEMSG_H

typedef nx_struct motemsg{
	nx_uint16_t nodeId;
	
	nx_uint16_t tempVal;
	nx_uint16_t humVal;	
	nx_uint16_t AccelX_data;
	nx_uint16_t AccelY_data;
	nx_int16_t Intersema_data[2];
	nx_uint16_t VisLight_data;
	nx_uint16_t InfLight_data;

}motemsg_t;


enum {
  AM_MOTEMSG = 1,
  TIMER_PERIOD_MILLI = 2000,
};

#endif /* WIRELESS_NETWORK_H */
