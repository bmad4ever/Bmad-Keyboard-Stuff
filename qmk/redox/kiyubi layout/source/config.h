#pragma once

/* Copyright 2017 Mattia Dal Ben
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "config_common.h"


/* USB Device descriptor parameter */

//#define VENDOR_ID       0xFEED
//#define PRODUCT_ID      0x6060
#define DEVICE_VER      0x0001
#define MANUFACTURER    Mattia Dal Ben
#define PRODUCT         Redox_wireless
//#define DESCRIPTION     q.m.k. keyboard firmware for Redox-w

/* key matrix size */
#define MATRIX_ROWS 5
#define MATRIX_COLS 14

/* define if matrix has ghost */
//#define MATRIX_HAS_GHOST

/* number of backlight levels */
//#define BACKLIGHT_LEVELS 3

//#define ONESHOT_TIMEOUT 500

/*
 * Feature disable options
 *  These options are also useful to firmware size reduction.
 */

/* disable debug print */
//#define NO_DEBUG

/* disable print */
//#define NO_PRINT

/* disable action features */
//#define NO_ACTION_LAYER
//#define NO_ACTION_TAPPING
//#define NO_ACTION_ONESHOT
//#define NO_ACTION_MACRO
//#define NO_ACTION_FUNCTION

//UART settings for communication with the RF microcontroller
#define SERIAL_UART_BAUD 1000000
#define SERIAL_UART_DATA UDR1
#define SERIAL_UART_UBRR (F_CPU / (16UL * SERIAL_UART_BAUD) - 1)
#define SERIAL_UART_TXD_READY (UCSR1A & _BV(UDRE1))
#define SERIAL_UART_RXD_PRESENT (UCSR1A & _BV(RXC1))
#define SERIAL_UART_INIT() do { \
    	/* baud rate */ \
    	UBRR1L = SERIAL_UART_UBRR; \
    	/* baud rate */ \
    	UBRR1H = SERIAL_UART_UBRR >> 8; \
    	/* enable TX and RX */ \
    	UCSR1B = _BV(TXEN1) | _BV(RXEN1); \
    	/* 8-bit data */ \
    	UCSR1C = _BV(UCSZ11) | _BV(UCSZ10); \
  	} while(0)

        













//======================================================
// MY CONFIGS
//======================================================

//this is required for the shift mod
#define ONESHOT_TAP_TOGGLE 2  // Tapping this number of times holds the key until tapped once again.

#undef ONESHOT_TIMEOUT
#define ONESHOT_TIMEOUT 1000  // Time (in ms) before the one shot key is released

//#define PERMISSIVE_HOLD
#define IGNORE_MOD_TAP_INTERRUPT


#define ONEHAND_ENABLE // allows swapping left/right keys

//======================================================
// MOUSE options
//======================================================
#if true

#undef MOUSEKEY_DELAY	           
#undef MOUSEKEY_INTERVAL	       
#undef MOUSEKEY_MAX_SPEED	       
#undef MOUSEKEY_TIME_TO_MAX	   
#undef MOUSEKEY_WHEEL_DELAY	   
#undef MOUSEKEY_WHEEL_INTERVAL	
#undef MOUSEKEY_WHEEL_MAX_SPEED	
#undef MOUSEKEY_WHEEL_TIME_TO_MAX

//#define MK_COMBINED

//except for delay, the max value is 255
#define  MOUSEKEY_DELAY	            0	 //Delay between pressing a movement key and cursor movement  
#define  MOUSEKEY_INTERVAL	        33	 //Time between cursor movements  
#define  MOUSEKEY_MAX_SPEED	        254 //Maximum cursor speed at which acceleration stops 
#define  MOUSEKEY_TIME_TO_MAX	    254	 //Time until maximum cursor speed is reached 
#define  MOUSEKEY_WHEEL_DELAY	    100  //Delay between pressing a wheel key and wheel movement
#define  MOUSEKEY_WHEEL_INTERVAL	100	 //Time between wheel movements
#define  MOUSEKEY_WHEEL_MAX_SPEED	8	 //Maximum number of scroll steps per scroll action
#define  MOUSEKEY_WHEEL_TIME_TO_MAX	254 //Time until maximum scroll speed is reached


#endif


//======================================================
// TAP DANCING options
//======================================================
#if true

#define TAPPING_TERM 200

#endif
