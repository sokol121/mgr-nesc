COMPONENT = EndDeviceAppC
PFLAGS += -I$(TOSDIR)/lib/printf
CFLAGS += -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/4bitle
SENSORBOARD=mts400

BUILD_EXTRA_DEPS = MoteMsg.java RouteMsg.java
CLEAN_EXTRA = $(BULID_EXTRA_DEPS) *.class
MoteMsg.java: MoteMsg.h
		mig java -target=$(PLATFORM) -java-classname=pl.edu.pw.MoteMsg MoteMsg.h motemsg -o $@
include $(MAKERULES)
