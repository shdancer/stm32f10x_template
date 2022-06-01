# 工程文件夹
TARGET = template
 
# č编译生成文件夹
BUILD_DIR = build
 
# C源文件
C_SOURCES =  \
$(wildcard User/*.c) \
$(wildcard CMSIS/*.c) \
$(wildcard Driver/*.c) \
Library/src/stm32f10x_gpio.c \
Library/src/stm32f10x_rcc.c

 
######################################
 
 
 
# ASM sources
ASM_SOURCES =  \
Startup/startup_stm32f10x_md.s
 
######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Og
 
 
#######################################
# binaries
#######################################
PREFIX = arm-none-eabi-
ifdef GCC_PATH
CC = $(GCC_PATH)/$(PREFIX)gcc
AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
CP = $(GCC_PATH)/$(PREFIX)objcopy
SZ = $(GCC_PATH)/$(PREFIX)size
DB = $(GCC_PATH)/$(PREFIX)gdb
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
DB = $(PREFIX)gdb
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# CFLAGS
#######################################
# cpu
CPU = -mcpu=cortex-m3
 
# fpu
# NONE for Cortex-M0/M0+/M3
 
# float-abi
 
 
# mcu
MCU = $(CPU) -mthumb $(FPU) $(FLOAT-ABI)
 
# macros for gcc
# AS defines
AS_DEFS = 
 
# C defines   宏定义标志
C_DEFS =  \
-DUSE_STDPERIPH_DRIVER \
-DSTM32F10X_MD
 
# AS includes
AS_INCLUDES = 
 
# C includes  C头文件路径
C_INCLUDES =  \
-ICMSIS \
-ICMSIS \
-ILibrary/inc \
-IUser \
-IDriver
 
# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections
 
CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections
 
ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif
 
 
# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"
 
 
#######################################
# LDFLAGS
#######################################
# link script  链接配置文件
LDSCRIPT = Startup/stm32_flash.ld
 
# libraries
#LIBS = -lc -lm -lnosys 
LIBS = -lc
LIBDIR = 
#LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections
LDFLAGS = $(MCU) -T$(LDSCRIPT) $(LIBDIR) $(LIBS) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections
 
# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin
 
 
#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))
 
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@
 
$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@
 
$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@
 
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@		
 
#######################################
# clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)

flash:
	openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
	-c init -c halt -c "flash write_image erase $(BUILD_DIR)/$(TARGET).hex" -c shutdown

run:
	openocd -f interface/stlink.cfg -f target/stm32f1x.cfg

debug:
	$(DB) $(BUILD_DIR)/$(TARGET).elf --tui \
	-ex="target extended-remote localhost:3333" \
	-ex="monitor reset halt" \
	-ex="load"


  
#######################################
# dependencies
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)
 
# *** EOF ***
