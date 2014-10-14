include .knightos/variables.make

ALL_TARGETS:=$(BIN)periodic $(APPS)periodic.app

$(BIN)periodic: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)periodic

$(APPS)periodic.app: config/periodic.app
	mkdir -p $(APPS)
	cp config/periodic.app $(APPS)

include .knightos/sdk.make
