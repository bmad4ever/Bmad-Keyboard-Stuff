#include QMK_KEYBOARD_H

// -------------------------------------------------------------------------------------------------------    
//   LAYOUT USAGE TIPS
// -------------------------------------------------------------------------------------------------------    

/*
    - When using LT(layer, key), double tap key and keep it pressed to spam key without activating layer
    - Use left thumb cluster with key caps that have a 'plane profile' (with small bevel margins) in order to facilitate comboing shift, ctrl and alt
    - Use tilted keys to swipe type to a lower row 
*/  




// -------------------------------------------------------------------------------------------------------    
//   redifine colors names     
// -------------------------------------------------------------------------------------------------------    
#if true

//failed to reproduce exact same behavior as the system. 
//as close as I could get without jeopardizing the typing experience. 
//The default system is behavior is the following:
//  With key and shift pressed, it should pause when when shift if released and then spam kc1.
//  With key pressed, it should stop inputing when shift is pressed.
//The implemented behavior does not allow spam when key is being pressed, only allows for a single character per click.

bool prevShiftState = false;
bool thisShiftState = false;
bool oneShotedShift = false;
uint16_t kc; //registered key code set by SHIFT_MOD

void SHIFT_MOD(uint16_t kc1,uint16_t kc2, keyrecord_t *record) 
{ 
      
      if (record->event.pressed ) { 
        if (thisShiftState) {  
          if ((QK_LSFT & kc2) == 0) {
              if(oneShotedShift) clear_oneshot_mods(); 
              unregister_mods(MOD_BIT(KC_LSFT)); 
          }
          register_code(kc = kc2); 
          if(!oneShotedShift) register_mods(MOD_BIT(KC_LSFT));
        } else {
            if ((QK_LSFT & kc1) != 0) register_mods(MOD_BIT(KC_LSFT));
            register_code(kc = kc1); 
            unregister_mods(MOD_BIT(KC_LSFT));
        }
        unregister_code(kc); //simplify and make consistent. user can't loop neither one of the characters.
      }
}

void SHIFT_MOD_MARK(uint16_t kc1, keyrecord_t *record) 
{ 
      if (record->event.pressed ) { 
        if (thisShiftState) {  
          clear_oneshot_mods();
          unregister_mods(MOD_BIT(KC_LSFT)); 
          
          register_mods(MOD_BIT(KC_LALT));
          
          SEND_STRING(SS_TAP(X_P8) SS_TAP(X_P2) SS_TAP(X_P5)  SS_TAP(X_P1) );
          
          unregister_mods(MOD_BIT(KC_LALT));
          
          if(!oneShotedShift) register_mods(MOD_BIT(KC_LSFT));
        } else {
            if ((QK_LSFT & kc1) != 0) register_mods(MOD_BIT(KC_LSFT));
            register_code(kc = kc1); 
            unregister_mods(MOD_BIT(KC_LSFT));
            unregister_code(kc); 
        }
      }
}

#define SHIFT_CLEAR_MOD() \
{ \
      unregister_code(kc); \
}
        //  prevActiveCustomKeyCode = 0; 
#endif    
// -------------------------------------------------------------------------------------------------------    
//   redifine colors names     
// -------------------------------------------------------------------------------------------------------    
#if true
//notes regarding leds on my keeb
// default set red => lights green
// default set green => lights red
// default set blue => lights yellow
// added a new code to use the additional blue light.

#undef red_led_off
#undef red_led_on
#undef grn_led_off
#undef grn_led_on
#undef set_led_off     
#undef set_led_red     
#undef set_led_green   
#undef set_led_yellow
#undef set_led_blue
#undef blu_led_off
#undef blu_led_on


#define red_led_off   PORTD |= (1<<1)
#define red_led_on    PORTD &= ~(1<<1)
#define blu_led_off   DDRD  &= ~1
#define blu_led_on    DDRD  |= 1
#define ylw_led_off   PORTF |= (1<<4)
#define ylw_led_on    PORTF &= ~(1<<4)
#define grn_led_off   PORTF |= (1<<5)
#define grn_led_on    PORTF &= ~(1<<5)


#define set_led_off     red_led_off;  grn_led_off;  ylw_led_off ;  blu_led_off
#define set_led_red     red_led_on ;  grn_led_off;  ylw_led_off ;  blu_led_off
#define set_led_green   red_led_off;  grn_led_on ;  ylw_led_off ;  blu_led_off
#define set_led_yellow  red_led_off;  grn_led_off;  ylw_led_on ;  blu_led_off
#define set_led_blue    red_led_off;  grn_led_off;  ylw_led_off ;  blu_led_on
#define set_led_all     red_led_on ;  grn_led_on ;  ylw_led_on ;  blu_led_on


#endif
    
// -------------------------------------------------------------------------------------------------------    
//   LAYERS IDs and descriptions
// -------------------------------------------------------------------------------------------------------   
#if true

#define LAYER_CODE(LAYER) (1UL << LAYER)
//use this macro to filter layers on a given state.
//  this is already defined somewhere else on qmk,
//  but to make it explicit I redefined it here albeit with a different name


#define _BASE 0
//used to setup the keyboard' layout

#define _NO_DELAY_PLUS_EXTRAS_BASE_OVERLAY 10
// a layer that removes One Shots and the like from the base layer and adds a KC_LOCK key
// useful when to spam mod keys without triggering one shots or to lock some key

#define _KIYUBI 1
//letters layouts only. swaps qwerty layout to beakl. Mind that OS must be using qwerty in order for beakl to work.

#define _QWERTY 2
//letters layout with some keys remaining from the vanilla qwerty layout for redox.
//standard qwerty, can be changed to other layout in the OS.

#define _SYMB 3
//symbols layer

// - - - - - - - - - - - -
// top row overlays
#define _TOP_NUMBERS 4
#define _TOP_FUNCS1 5
#define _TOP_FUNCS2 6
#define _TOP_MEDIA 7
// - - - - - - - - - - - -

#define _ARROW_N_NUMBERS 8
//navigation using arrows, home, end, etc... 
//also has shortcuts for copy, paste, and similar...
//also has a numpad on the right half

#define _MOUSE 9
//navigation using mouse, home, end, etc... 
//also has shortcuts for copy, paste, and similar...


#endif

// -------------------------------------------------------------------------------------------------------    
//   CUSTOM KEY ALIASES AND CUSTOM KEYCODES
// -------------------------------------------------------------------------------------------------------   
#if true


enum custom_keycodes {
  //macro related
  QMKBEST = SAFE_RANGE,
  CMMxDQO,  // comma  or  double quote when shifted 
  //CMMxQUO,  // comma  or  quote when shifted
  //CMMxSCL,  // comma  or  semicolon when shifted
  //COLxRMK,  // colon   or   reference mark when shifted 
  //COLxHIF,  // colon  or  hifen when shifted
  DOTxAT,  // dot  or  at sign when shifted 
  //DOTxCOL,  // dot  or  colon when shifted
  //DOTxDQO,  // dot  or  double quote when shifted
  //DQOxHIF,  // double quote  or  hifen when shifted
  //QUOxGRV,  // quote  or  grave when shifted
  QUOxRMK,  // quote   or   reference mark when shifted 
  //SCLxAT,    // semicolon   or   at sign when shifted
  SCLxGRV,  // semicolon  or  grave when shifted 
// MOUSE_L,
};

// Shortcuts to make keymap more readable
#define TESTMCR QMKBEST

#define SYM_LV   MO(_SYMB)
#define SYM_L   OSL(_SYMB)
#define AxN_L   MO(_ARROW_N_NUMBERS)

#define KC_ALAS LALT_T(KC_PAST)
#define KC_CTPL LCTL_T(KC_BSLS)

#define KC_NAGR LT(_ARROW_N_NUMBERS, KC_GRV)
#define KC_NAMI LT(_ARROW_N_NUMBERS, KC_MINS)

        
#define GOTO1__ LCTL(KC_G)
#define GOTO2__ LCTL(KC_D)

#define KCcCOPY LCTL(KC_C)
#define KCxCUT_ LCTL(KC_X)
#define KCzUNDO LCTL(KC_Z)
#define KCyREDO LCTL(KC_Y)
#define KCvPSTE LCTL(KC_V)
#define KCdDUP_ LCTL(KC_D)
#define KCfFIND LCTL(KC_F)
#define KChRPLC LCTL(KC_H)

//#define CTL_ALT LCTL(KC_LALT)
#define ALT_ENT LALT(KC_ENT)

#define SYM_LxE LT(_SYMB, KC_ENT)
#define NAV_LxT LT(_ARROW_N_NUMBERS, KC_TAB)

#define OSM_SFT OSM(MOD_LSFT)
#define OSM_CTL OSM(MOD_LCTL)
#define OSM_ALT OSM(MOD_LALT)
#define OSM_RLT OSM(MOD_RALT)
#define CTL_ALT OSM(MOD_LCTL | MOD_LALT)
#define OSM_MEH OSM(MOD_MEH)
#define OSM_GUI OSM(MOD_LGUI)

#define TO_BASE TO(_BASE)
#define TO_QWER TO(_QWERTY)
#define TO_KIYUB TO(_KIYUBI)

#define TG_NDLAY TG(_NO_DELAY_PLUS_EXTRAS_BASE_OVERLAY)


#define TG_MOSE TG(_MOUSE)


#define SH_CAPS SH_T(KC_CAPS)
#define SH_PAUS SH_T(KC_PAUS)


//-----------------------------------
//     TAP DANCE 

enum   {
  CT_GUI=0,
  CT_APP,
  CT_TOP
};

/*void dance_gui_key (qk_tap_dance_state_t *state, void *user_data) {
  //clear_oneshot_mods();
  //clear_keyboard();
  
  switch (state->count) {
    case 1:
    set_oneshot_mods(MOD_LGUI);
    break;
    case 2:
    tap_code(KC_LGUI); 
    break;
    default:
    reset_tap_dance (state);
    break;
  }
}*/

void dance_app_key (qk_tap_dance_state_t *state, void *user_data) {
  clear_oneshot_mods();
  clear_keyboard();
  
  switch (state->count) {
    case 1:
    tap_code(KC_ESC);
    break;
    case 2:
    tap_code(KC_APP);
    break;
    default:
    reset_tap_dance (state);
    break;
  }
}

    
void dance_top_row_layer_key (qk_tap_dance_state_t *state, void *user_data) {
  layer_off(_TOP_NUMBERS);
  layer_off(_TOP_MEDIA);
  layer_off(_TOP_FUNCS1);
  layer_off(_TOP_FUNCS2);
  set_led_off;
  
  switch (state->count) {
    case 1:
    layer_on(_TOP_FUNCS1);
    blu_led_on;
    break;
    case 2:
    layer_on(_TOP_FUNCS2);
    grn_led_on;
    break;
    case 3:
    layer_on(_TOP_MEDIA);
    ylw_led_on;
    break;
    case 4:
    layer_on(_TOP_NUMBERS);
    red_led_on;
    break;
    default:
    reset_tap_dance (state);
    break;
  }
}

qk_tap_dance_action_t tap_dance_actions[] = {
// [CT_GUI] = ACTION_TAP_DANCE_FN (dance_gui_key),
 [CT_APP] = ACTION_TAP_DANCE_FN (dance_app_key),
 [CT_TOP] = ACTION_TAP_DANCE_FN (dance_top_row_layer_key),
 };

#define TD_GUI TD(CT_GUI)
#define TD_APP TD(CT_APP)
#define TD_TOP TD(CT_TOP)


#endif



//,UC_M_LN ,UC_M_WI ,UC_M_WC ,UC_M_OS

// -------------------------------------------------------------------------------------------------------    
//   LAYOUTS
// -------------------------------------------------------------------------------------------------------   

#define ADVANCED_BASE_LAYOUT

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      BASE LAYER      
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------

#ifdef ADVANCED_BASE_LAYOUT
//ADVANCED
    [_BASE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     TG_NDLAY,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,                                            XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_INS  ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_TAB  ,                          OSM_RLT ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_DEL  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_CAPS ,XXXXXXX ,SH_TG   ,TO_QWER ,TO_KIYUB,RESET   ,KC_ENT  ,                          KC_ESC  ,RESET   ,TO_KIYUB,TO_QWER ,SH_TG   ,XXXXXXX ,KC_PAUS ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     SH_OS   ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,OSM_ALT ,OSM_ALT ,        TD_APP  ,OSM_GUI ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,SH_OS   ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     TO_BASE ,KC_SLCK ,KC_PSCR ,OSM_MEH ,     SYM_L   ,    OSM_SFT ,OSM_CTL ,        KC_BSPC ,KC_SPC  ,    NAV_LxT ,     TG_MOSE ,TD_TOP  ,KC_NLCK ,KC_SYSREQ
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),


#else
//VANILLA
  [_BASE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,                                            XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_INS  ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_TAB  ,                          KC_RALT ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_DEL  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_QUES ,XXXXXXX ,SH_TG   ,TO_QWER ,TO_BEAK ,RESET   ,KC_ENT  ,                          KC_ESC  ,RESET   ,TO_BEAK ,TO_QWER ,SH_TG   ,XXXXXXX ,KC_EXLM ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_CAPS ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_LALT ,KC_LALT ,        KC_APP  ,KC_RGUI ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_PAUS ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     TO_BASE ,KC_SLCK ,KC_PSCR ,OSM_MEH ,     SYM_LV  ,    KC_LSFT ,KC_LCTL ,        KC_BSPC ,KC_SPC  ,    AxN_L   ,     TG_MOSE ,TD_TOP  ,KC_NLCK ,KC_SYSREQ
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
#endif



      [_NO_DELAY_PLUS_EXTRAS_BASE_OVERLAY] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          KC_RALT ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,KC_LALT ,KC_LALT ,        _______ ,KC_LOCK ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     SYM_LV  ,    KC_LSFT ,KC_LCTL ,        _______ ,_______ ,    AxN_L   ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),    


  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //     ALPHABET BASE LAYERS           ALPHABET BASE LAYERS            ALPHABET BASE LAYERS            ALPHABET BASE LAYERS            ALPHABET BASE LAYERS  
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    [_KIYUBI] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,KC_1    ,KC_2    ,KC_3    ,KC_4    ,KC_5    ,                                            KC_6    ,KC_7    ,KC_8    ,KC_9    ,KC_0    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,QUOxRMK ,KC_Y    ,KC_O    ,KC_F    ,SCLxGRV ,_______ ,                          _______ ,KC_J    ,KC_C    ,KC_L    ,KC_P    ,CMMxDQO ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_H    ,KC_I    ,KC_E    ,KC_A    ,KC_U    ,_______ ,                          _______ ,KC_D    ,KC_S    ,KC_T    ,KC_N    ,KC_R    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_Q    ,KC_X    ,DOTxAT  ,KC_K    ,KC_Z    ,_______ ,_______ ,        _______ ,_______ ,KC_W    ,KC_G    ,KC_M    ,KC_B    ,KC_V    ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
  
  //REDOX VANILLA QWERTY LAYOUT WITH LGUI BUTTON MOVED TO THE TOP ROW AND ARROW KEYS REMOVED
  [_QWERTY] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,KC_1    ,KC_2    ,KC_3    ,KC_4    ,KC_5    ,                                            KC_6    ,KC_7    ,KC_8    ,KC_9    ,KC_0    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_TAB  ,KC_Q    ,KC_W    ,KC_E    ,KC_R    ,KC_T    ,_______ ,                          _______ ,KC_Y    ,KC_U    ,KC_I    ,KC_O    ,KC_P    ,KC_EQL  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_CAPS ,KC_A    ,KC_S    ,KC_D    ,KC_F    ,KC_G    ,_______ ,                          _______ ,KC_H    ,KC_J    ,KC_K    ,KC_L    ,KC_SCLN ,KC_QUOT ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_LSFT ,KC_Z    ,KC_X    ,KC_C    ,KC_V    ,KC_B    ,_______ ,_______ ,        _______ ,_______ ,KC_N    ,KC_M    ,KC_COMM ,KC_DOT  ,KC_SLSH ,KC_RSFT ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,KC_PPLS ,KC_PMNS ,KC_ALAS ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    SYMBOL LAYERS           SYMBOL LAYERS           SYMBOL LAYERS           SYMBOL LAYERS           SYMBOL LAYERS           SYMBOL LAYERS       
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------

  [_SYMB] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_PIPE ,KC_AMPR ,KC_PAST ,KC_COLN ,KC_CIRC ,_______ ,                          _______ ,KC_CIRC ,KC_HASH ,KC_DLR  ,KC_PERC ,KC_DQUO ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_EXLM ,KC_PSLS ,KC_PMNS ,KC_EQL  ,KC_TILD ,_______ ,                          _______ ,KC_TILD ,KC_LCBR ,KC_LPRN ,KC_LBRC ,KC_QUES ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_PPLS ,KC_LABK ,KC_RABK ,KC_UNDS ,KC_PSLS ,_______ ,_______ ,        _______ ,_______ ,KC_PSLS ,KC_RCBR ,KC_RPRN ,KC_RBRC ,KC_BSLS ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,KC_UNDS ,    _______ ,     _______ ,_______ ,_______ ,_______ 
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

 
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    TOP ROW OVERLAYS                TOP ROW OVERLAYS            TOP ROW OVERLAYS            TOP ROW OVERLAYS            TOP ROW OVERLAYS
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    [_TOP_NUMBERS] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,KC_1    ,KC_2    ,KC_3    ,KC_4    ,KC_5    ,                                            KC_6    ,KC_7    ,KC_8    ,KC_9    ,KC_0    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

      [_TOP_MEDIA] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     KC_MAIL ,KC_CALC ,KC_MYCM ,KC_MSEL ,KC_BRID ,KC_BRIU ,                                            KC_MPRV ,KC_MNXT ,KC_MUTE ,KC_VOLD ,KC_VOLU ,KC_MPLY ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

      [_TOP_FUNCS1] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     KC_F1   ,KC_F2   ,KC_F3   ,KC_F4   ,KC_F5   ,KC_F6   ,                                            KC_F7   ,KC_F8   ,KC_F9   ,KC_F10  ,KC_F11  ,KC_F12  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

      [_TOP_FUNCS2] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     KC_F13  ,KC_F14  ,KC_F15  ,KC_F16  ,KC_F17  ,KC_F18  ,                                            KC_F19  ,KC_F20  ,KC_F21  ,KC_F22  ,KC_F23  ,KC_F24  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),    

  
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    NAVIGATION LAYERS           NAVIGATION LAYERS           NAVIGATION LAYERS           NAVIGATION LAYERS           NAVIGATION LAYERS
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    [_ARROW_N_NUMBERS] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_PGUP ,KC_UP   ,KC_PGDN ,KCcCOPY ,_______ ,                          _______ ,KC_PMNS ,KC_7    ,KC_8    ,KC_9    ,KC_PEQL ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_LEFT ,KC_DOWN ,KC_RGHT ,KCvPSTE ,_______ ,                          _______ ,KC_PPLS ,KC_4    ,KC_5    ,KC_6    ,KC_PSLS ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCdDUP_ ,KCyREDO ,KCzUNDO ,KCxCUT_ ,_______ ,_______ ,        _______ ,_______ ,KC_0    ,KC_1    ,KC_2    ,KC_3    ,KC_PAST ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     KC_0    ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
   
  
      [_MOUSE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_HOME ,KC_MS_U ,KC_END  ,KCcCOPY ,_______ ,                          _______ ,KC_PMNS ,KC_WH_L ,KC_WH_R ,KC_WH_U ,KC_ACL1 ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_MS_L ,KC_MS_D ,KC_MS_R ,KCvPSTE ,_______ ,                          _______ ,KC_PPLS ,KC_BTN1 ,KC_BTN2 ,KC_WH_D ,KC_ACL2 ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCdDUP_ ,KCyREDO ,KCzUNDO ,KCxCUT_ ,_______ ,_______ ,        _______ ,_______ ,_______ ,KC_BTN3 ,KC_BTN4 ,KC_BTN5 ,KC_ACL0 ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),  
  
  

  
};



// -------------------------------------------------------------------------------------------------------    
//   METHODS
// -------------------------------------------------------------------------------------------------------

bool FlashBlueLigthLayer(uint16_t keycode){
    return keycode == TG_NDLAY ||
        keycode == TO_KIYUB || 
        keycode == TO_QWER || 
        keycode == TO_BASE;
}


bool swap_pressed = false;
void matrix_scan_user(void) {  
    set_led_off;
  
    if( layer_state & 
          (
              LAYER_CODE(_SYMB) 
              | LAYER_CODE(_ARROW_N_NUMBERS)
          )   
      ) red_led_on;

    if(swap_pressed) grn_led_on;
    
    if(layer_state & LAYER_CODE(_MOUSE)) ylw_led_on;   
}


bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  
  if(FlashBlueLigthLayer(keycode)){
    if (record->event.pressed) blu_led_on;
    return true;
  }
      
  if(keycode == SH_OS){
    swap_pressed = record->event.pressed;
    return true;
  }

  thisShiftState = get_mods() & MOD_MASK_SHIFT ;
  thisShiftState|= (record->event.pressed && keycode == OSM_SFT) ;
  thisShiftState&= ! (!record->event.pressed && keycode == OSM_SFT) ;
  oneShotedShift = ( get_oneshot_mods() & MOD_LSFT );
  thisShiftState|= oneShotedShift;
  
  if(thisShiftState != prevShiftState)
    SHIFT_CLEAR_MOD()
  
  prevShiftState = thisShiftState;
  
  switch (keycode) {
     
    case CMMxDQO:
        SHIFT_MOD(KC_COMM, KC_DQUO,record);
        return false;             
    //case CMMxQUO:
    //    SHIFT_MOD(KC_COMM, KC_QUOT,record);
    //return false;
    //case CMMxSCL:
    //    SHIFT_MOD(KC_COMM, KC_SCLN,record);
    //    return false;
    case DOTxAT:
        SHIFT_MOD(KC_DOT, KC_AT,record);
        return false;     
    //case DOTxCOL:
    //    SHIFT_MOD(KC_DOT,KC_COLN ,record);
    //    return false;
    //case DOTxDQO:
    //    SHIFT_MOD(KC_DOT, KC_DQUO,record);
    //    return false;        
    //case DQOxHIF:
    //    SHIFT_MOD(KC_DQUO, KC_PMNS,record);
    //    return false;
    //case SCLxAT:
    //    SHIFT_MOD(KC_SCLN, KC_AT,record);
    //    return false;
    case SCLxGRV:
        SHIFT_MOD(KC_SCLN, KC_GRV,record);
        return false;     
    //case QUOxGRV:
    //    SHIFT_MOD(KC_QUOT, KC_GRV,record);
    //    return false;
    //      
    //case COLxRMK:
    //    SHIFT_MOD_MARK(KC_COLN, record);
    //        return false;  
    case QUOxRMK:
        SHIFT_MOD_MARK(KC_QUOT, record);
            return false;  
          
          
    case TO_BASE:
      if (record->event.pressed) set_led_off;
    return true;   
    
    
    
  }
  return true;
};
