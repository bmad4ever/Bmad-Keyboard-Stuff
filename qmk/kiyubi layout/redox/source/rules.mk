# Do not enable SLEEP_LED_ENABLE. it uses the same timer as BACKLIGHT_ENABLE
BOOTMAGIC_ENABLE           = no	  # Virtual DIP switch configuration(+1000)
CONSOLE_ENABLE             = no	  # Console for debug(+400)
CUSTOM_MATRIX              = lite # Remote matrix from the wireless bridge
SLEEP_LED_ENABLE           = no   # Breathing sleep LED during USB suspend

MOUSEKEY_ENABLE            = yes  # Mouse keys(+4700)
EXTRAKEY_ENABLE            = yes  # Audio control and System control(+450)

COMMAND_ENABLE             = no   # Commands for debug and configuration
MAGIC_ENABLE 	           = no   # Not the same as COMMAND or BOOTMAGIC_ENABLE ?

AUTO_SHIFT_ENABLE          = yes
COMBO_ENABLE               = yes
DYNAMIC_MACRO_ENABLE       = no  
KEY_LOCK_ENABLE            = yes
PROGRAMMABLE_BUTTON_ENABLE = no
SWAP_HANDS_ENABLE          = yes
TAP_DANCE_ENABLE           = yes
TRI_LAYER_ENABLE           = no

SPACE_CADET_ENABLE         = no   # https://docs.qmk.fm/#/feature_space_cadet
GRAVE_ESC_ENABLE           = no   # https://docs.qmk.fm/#/keycodes?id=grave-escape

BACKLIGHT_ENABLE           = no    # Enable keyboard backlight functionality
MIDI_ENABLE                = no    # MIDI controls
NKRO_ENABLE                = no	   # USB Nkey Rollover - not yet supported in LUFA
RGBLIGHT_ENABLE            = no
UNICODE_ENABLE             = no    # Unicode
UNICODEMAP_ENABLE          = no

LTO_ENABLE                 = yes   # link time optimizations

# project specific files
#SRC += matrix.c
#UART_DRIVER_REQUIRED = yes
