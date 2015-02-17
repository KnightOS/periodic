include .knightos/variables.make

ALL_TARGETS:=$(BIN)periodic $(APPS)periodic.app $(SHARE)icons/periodic.img

$(BIN)periodic: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)periodic

$(APPS)periodic.app: config/periodic.app
	mkdir -p $(APPS)
	cp config/periodic.app $(APPS)

$(SHARE)icons/periodic.img: config/periodic.png
	mkdir -p $(SHARE)icons
	kimg -c config/periodic.png $(SHARE)icons/periodic.img

include .knightos/sdk.make
