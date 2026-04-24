# Makefile — Build the C-model bit-exact driver
#
# Usage:
#   make              # build cmodel_driver
#   make clean        # remove build artifacts

CC      ?= gcc
CFLAGS  ?= -O2 -Wall -Wextra -std=c99
LDFLAGS ?= -lm

REF_DIR := ../../ref

SRCS := cmodel_driver.c \
        $(REF_DIR)/lpadc_osr.c \
        $(REF_DIR)/sysparm.c

INCLUDES := -I$(REF_DIR)

TARGET := cmodel_driver

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)
