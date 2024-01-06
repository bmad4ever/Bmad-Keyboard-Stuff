#pragma once


//this is required for the shift mod
#define ONESHOT_TAP_TOGGLE 2  // Tapping this number of times holds the key until tapped once again.
//#define TAPPING_TERM_PER_KEY  

#undef ONESHOT_TIMEOUT
#define ONESHOT_TIMEOUT 1000  // Time (in ms) before the one shot key is released

#undef PERMISSIVE_HOLD


#define ONEHAND_ENABLE // allows swapping left/right keys


#define AUTO_SHIFT_DISABLED_AT_STARTUP
//#define AUTO_SHIFT_TIMEOUT 150
//#define NO_AUTO_SHIFT_SPECIAL

//======================================================
// MOUSE options
//======================================================
#if true


//except for delay, the max value is 255
#define  MOUSEKEY_DELAY	            0	 //Delay between pressing a movement key and cursor movement  
#define  MOUSEKEY_INTERVAL	        20	 //Time between cursor movements  
#define  MOUSEKEY_MAX_SPEED	        7    //Maximum cursor speed at which acceleration stops 
#define  MOUSEKEY_TIME_TO_MAX	    60	 //Time until maximum cursor speed is reached 
#define  MOUSEKEY_WHEEL_DELAY	    0    //Delay between pressing a wheel key and wheel movement
#define  MOUSEKEY_WHEEL_INTERVAL	20	 //Time between wheel movements
#define  MOUSEKEY_WHEEL_MAX_SPEED	7	 //Maximum number of scroll steps per scroll action
#define  MOUSEKEY_WHEEL_TIME_TO_MAX	60  //Time until maximum scroll speed is reached


#endif


//======================================================
// TAP DANCING options
//======================================================
#if true

#define TAPPING_TERM 200

#endif


//======================================================
// COMBO options
//======================================================
#if true

#define COMBO_TERM 50  // 50ms is the default
#define COMBO_KEY_BUFFER_LENGTH 8
#define COMBO_BUFFER_LENGTH 4
//#define COMBO_MUST_HOLD_MODS
//#define COMBO_HOLD_TERM 150

#endif
