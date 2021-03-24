# MCU name
MCU = atmega32u4

# Bootloader selection
#   Teensy       halfkay
#   Pro Micro    caterina
#   Atmel DFU    atmel-dfu
#   LUFA DFU     lufa-dfu
#   QMK DFU      qmk-dfu
#   ATmega32A    bootloadHID
#   ATmega328P   USBasp
BOOTLOADER = caterina

# Build Options
#   comment out to disable the options.
#
#BOOTMAGIC_ENABLE = yes	# Virtual DIP switch configuration(+1000)
MOUSEKEY_ENABLE = yes	# Mouse keys(+4700)
EXTRAKEY_ENABLE = yes	# Audio control and System control(+450)
#CONSOLE_ENABLE = yes	# Console for debug(+400)
COMMAND_ENABLE = yes   # Commands for debug and configuration
CUSTOM_MATRIX = yes    # Remote matrix from the wireless bridge
# Do not enable SLEEP_LED_ENABLE. it uses the same timer as BACKLIGHT_ENABLE
#SLEEP_LED_ENABLE = yes  # Breathing sleep LED during USB suspend
#NKRO_ENABLE = yes		# USB Nkey Rollover - not yet supported in LUFA
#COMBO_ENABLE=yes
#BACKLIGHT_ENABLE = yes  # Enable keyboard backlight functionality
#MIDI_ENABLE = yes 		# MIDI controls
#UNICODE_ENABLE = yes 		# Unicode
#UNICODEMAP_ENABLE = yes
#BLUETOOTH_ENABLE = yes # Enable Bluetooth with the Adafruit EZ-Key HID
TAP_DANCE_ENABLE = yes
SWAP_HANDS_ENABLE = yes
KEY_LOCK_ENABLE = yes
LTO_ENABLE = yes # link time optimizations


USB = /dev/ttyACM0

OPT_DEFS += -DREDOX_W_PROMICRO
INTERPHASE_UPLOAD_COMMAND = while [ ! -r $(USB) ]; do sleep 1; done; \
                         avrdude -p $(MCU) -c avr109 -U flash:w:$(TARGET).hex -P $(USB)
    
                         
# # project specific files
SRC = matrix.c

# upload: build
# 	$(REDOX_W_UPLOAD_COMMAND)
