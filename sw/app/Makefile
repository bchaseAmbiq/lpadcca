CC      ?= arm-none-eabi-gcc
OBJCOPY ?= arm-none-eabi-objcopy
SIZE    ?= arm-none-eabi-size

CFLAGS  = -mcpu=cortex-m55 -mthumb -mfloat-abi=hard -mfpu=fpv5-d16 \
          -Os -g -Wall -Wextra -std=c99 \
          -ffunction-sections -fdata-sections \
          -I../hal -I../driver

LDFLAGS = -mcpu=cortex-m55 -mthumb -mfloat-abi=hard -mfpu=fpv5-d16 \
          -Wl,--gc-sections -specs=nosys.specs -specs=nano.specs \
          -T linker.ld

SRCS = main.c ../driver/osr_drv.c
OBJS = $(SRCS:.c=.o)
TARGET = osr_app

.PHONY: all clean

all: $(TARGET).elf $(TARGET).bin
	$(SIZE) $(TARGET).elf

$(TARGET).elf: $(OBJS) linker.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).bin
