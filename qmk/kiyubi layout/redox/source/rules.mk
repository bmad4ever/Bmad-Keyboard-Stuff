# Do not enable SLEEP_LED_ENABLE. it uses the same timer as BACKLIGHT_ENABLE
CUSTOM_MATRIX     = lite # Remote matrix from the wireless bridge
BOOTMAGIC_ENABLE  = no	# Virtual DIP switch configuration(+1000)
SLEEP_LED_ENABLE  = no  # Breathing sleep LED during USB suspend
CONSOLE_ENABLE    = no	# Console for debug(+400)


MOUSEKEY_ENABLE   = yes	# Mouse keys(+4700)
EXTRAKEY_ENABLE   = yes	# Audio control and System control(+450)
COMMAND_ENABLE    = yes # Commands for debug and configuration

NKRO_ENABLE       = no	# USB Nkey Rollover - not yet supported in LUFA
COMBO_ENABLE      = no
BACKLIGHT_ENABLE  = no  # Enable keyboard backlight functionality
MIDI_ENABLE       = no 	# MIDI controls
UNICODE_ENABLE    = no 	# Unicode
UNICODEMAP_ENABLE = no

TAP_DANCE_ENABLE  = yes
SWAP_HANDS_ENABLE = yes
KEY_LOCK_ENABLE   = yes
AUTO_SHIFT_ENABLE = yes

LTO_ENABLE        = yes   # link time optimizations

# project specific files
#SRC += matrix.c
#UART_DRIVER_REQUIRED = yes
