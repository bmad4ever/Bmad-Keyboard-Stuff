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
//   CUSTOM BEHAVIORS  
// -------------------------------------------------------------------------------------------------------    
#if 1

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


void SWAP_DOMINANT_HAND(keyrecord_t *record){
    if (record->event.pressed ) { 
      leftDominantMode=!leftDominantMode;  
      swap_hands=!swap_hands;
    }
}


#define SHIFT_CLEAR_MOD() \
{ \
      unregister_code(kc); \
}


//-----------------------------------------------------------------
layer_state_t pseudo_layer_hack = 0;
// pseudo_layer_hack keeps track of the NAVIGATION & SYMBOL states
// in order to implement a functionality similar to tri-layer.
// when both mods are pressed, neither layer is active and 
// "normal" key is send instead ( F24 as of last implementation ) 


#endif 

// -------------------------------------------------------------------------------------------------------    
//   redifine colors names     
// -------------------------------------------------------------------------------------------------------    
#if 1
//notes regarding leds on my keeb
// default set red => lights green
// default set green => lights red
// default set blue => lights yellow
// added a new code to use the additional blue light.

// leds order: B R Y G

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
#define blu_led_off   PORTD |= 1
#define blu_led_on    PORTD &= ~(1)
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
#if 1

#define LAYER_CODE(LAYER) ((layer_state_t)1 << LAYER)
//use this macro to filter layers on a given state.


#define _BASE 0
//used to setup the keyboard' layout

#define _KIYUBI 1
//letters layouts only. swaps qwerty layout to beakl. Mind that OS must be using qwerty in order for beakl to work.

#define _QWERTY 2
//letters layout with some keys remaining from the vanilla qwerty layout for redox.
//standard qwerty, can be changed to other layout in the OS.

#define _SYMB 3
//symbols layer

#define _FUNCTIONS 4
// all F keys, 1 to 24

// - - - - - - - - - - - -
// top row overlays
#define _TOP_NUMBERS 5
#define _TOP_FUNCS1 6
#define _TOP_FUNCS2 7
#define _TOP_MEDIA 8
// - - - - - - - - - - - -

#define _ARROW_N_NUMBERS 9
//navigation using arrows, home, end, etc... 
//also has shortcuts for copy, paste, and similar...
//also has a numpad on the right half

#define _MOUSE 10
//navigation using mouse, home, end, etc... 
//also has shortcuts for copy, paste, and similar...

#define _NO_DELAY_OVERLAY 11
// a layer that removes One Shots and the like from the base layer
// useful to spam mod keys without triggering one shots and have no delays on key presses

#define _GAMING_OVERLAY 12
// similar to no delay layer but without thumb layers and w/ some key code swaps and with a QK_LOCK key

#endif

// -------------------------------------------------------------------------------------------------------    
//   CUSTOM KEY ALIASES AND CUSTOM KEYCODES
// -------------------------------------------------------------------------------------------------------   
#if 1


enum custom_keycodes {
  QMKBEST = SAFE_RANGE,
  CMMxDQO,  // comma  or  double quote when shifted 
  DOTxAT,  // dot  or  at sign when shifted 
  QUOxRMK,  // quote   or   reference mark when shifted 
  SCLxGRV,  // semicolon  or  grave when shifted 
  SW_HAND,
};

// Shortcuts to make keymap more readable
#define TESTMCR QMKBEST

#define SYM_LV   MO(_SYMB)
#define SYM_L   OSL(_SYMB)
#define AxN_L   MO(_ARROW_N_NUMBERS)
//#define MO_FUNC MO(_FUNCTIONS)

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
#define FNC_LxP LT(_FUNCTIONS, KC_PAUS)

#define OSM_SFT OSM(MOD_LSFT)
#define OSM_CTL OSM(MOD_LCTL)
#define OSM_ALT OSM(MOD_LALT)
#define OSM_RLT OSM(MOD_RALT)
#define CTL_ALT OSM(MOD_LCTL | MOD_LALT)
#define SFT_CTL OSM(MOD_LSFT | MOD_LCTL)
#define SFT_ALT OSM(MOD_LSFT | MOD_LALT)
#define OSM_MEH OSM(MOD_MEH)  // Shift + Control + Alt
#define OSM_GUI OSM(MOD_LGUI)

#define TO_BASE TO(_BASE)
#define TO_QWER TO(_QWERTY)
#define TO_KIYUB TO(_KIYUBI)

#define TG_NDLAY TG(_NO_DELAY_OVERLAY)


#define TG_MOSE TG(_MOUSE)


#define SH_CAPS SH_T(KC_CAPS)
#define SH_PAUS SH_T(KC_PAUS)

#define CAPxF22 LT(0,KC_CAPS)


// - - - - - - - - - - - - - - - - - -
//     TAP DANCE 

enum   {
  CT_GUI=0,
  CT_APP,
  CT_TOP, // top row overlay
  CT_BLO, // "base" layer overlay
  TD_ESC_ALTF4, // escape -> Alt + F4
};


void soft_reset(void){
  clear_oneshot_mods();
  clear_mods();
  clear_oneshot_locked_mods();
  clear_keyboard();
  cancel_key_lock();
}

void go_to_base_reset(void){
  blu_led_on;
  
  soft_reset();
  
#ifdef AUTO_SHIFT_ENABLE
#ifdef AUTO_SHIFT_DISABLED_AT_STARTUP 
	autoshift_disable();
#else
	autoshift_enable();
#endif
#endif

}


void dance_app_key (tap_dance_state_t *state, void *user_data) {
  soft_reset();

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

    
void dance_top_row_layer_key (tap_dance_state_t *state, void *user_data) {
  layer_off(_TOP_NUMBERS);
  layer_off(_TOP_MEDIA);
  layer_off(_TOP_FUNCS1);
  layer_off(_TOP_FUNCS2);
  set_led_off;
  
  switch (state->count) {
    case 1:
    layer_on(_TOP_FUNCS1);
    grn_led_on; ylw_led_on;
    break;
    case 2:
    layer_on(_TOP_FUNCS2);
    grn_led_on; red_led_on;
    break;
    case 3:
    layer_on(_TOP_MEDIA);
    grn_led_on; blu_led_on;
    break;
    case 4:
    layer_on(_TOP_NUMBERS);
    grn_led_on; red_led_on; ylw_led_on;
    break;
    default:
    reset_tap_dance (state);
    break;
  }
}


void dance_base_layer_overlay (tap_dance_state_t *state, void *user_data) {
  soft_reset();
  set_led_off;
  
  switch (state->count) {
    case 1:
    layer_off(_NO_DELAY_OVERLAY);
    layer_off(_GAMING_OVERLAY);
    grn_led_on; ylw_led_on;
    break;
    case 2:
    layer_on(_NO_DELAY_OVERLAY);
    layer_off(_GAMING_OVERLAY);
    grn_led_on; red_led_on;
    break;
    case 3:
    layer_off(_NO_DELAY_OVERLAY);
    layer_on(_GAMING_OVERLAY);
    grn_led_on; blu_led_on;
    break;
    default:
    reset_tap_dance (state);
    break;
  }
}


tap_dance_action_t tap_dance_actions[] = {
 [CT_APP] = ACTION_TAP_DANCE_FN (dance_app_key),
 [CT_TOP] = ACTION_TAP_DANCE_FN (dance_top_row_layer_key),
 [CT_BLO] = ACTION_TAP_DANCE_FN (dance_base_layer_overlay),
 [TD_ESC_ALTF4] = ACTION_TAP_DANCE_DOUBLE(KC_ESC, LALT(KC_F4)),
 };

#define TD_APP TD(CT_APP)
#define TD_TOP TD(CT_TOP)
#define TD_BLO TD(CT_BLO)
#define TD_ESC TD(TD_ESC_ALTF4)



// - - - - - - - - - - - - - - - - - -
//     COMBOS 

enum combo_events {
OSMSA , // One Shot Modifier ( named after sent key )
OSMSC ,
OSMCA ,
OSMSCA,
RTCC1, // right thumb cluster combo 1 ( named after pressed keys )
RTCC2,
};

const uint16_t PROGMEM OSMSA_combo[] = {OSM_SFT, OSM_ALT, COMBO_END};
const uint16_t PROGMEM OSMSC_combo[] = {OSM_SFT, OSM_CTL, COMBO_END};
const uint16_t PROGMEM OSMCA_combo[] = {OSM_CTL, OSM_ALT, COMBO_END};
const uint16_t PROGMEM OSMSCA_combo[] = {OSM_SFT, OSM_CTL, OSM_ALT, COMBO_END};
const uint16_t PROGMEM RTCC1_combo[] = {KC_BSPC, TD_APP, COMBO_END};
const uint16_t PROGMEM RTCC2_combo[] = {OSM_GUI, KC_SPC, COMBO_END};
//const uint16_t PROGMEM F24C_combo[] = {SYM_L, NAV_LxT, COMBO_END}; // pseudo, not a combo, but similar
combo_t key_combos[] = {
    [OSMSA]  = COMBO(OSMSA_combo   , SFT_ALT)  ,
    [OSMSC]  = COMBO(OSMSC_combo   , SFT_CTL)  ,
    [OSMCA]  = COMBO(OSMCA_combo   , CTL_ALT)  ,
    [OSMSCA] = COMBO(OSMSCA_combo  , OSM_MEH)  ,
    [RTCC1]  = COMBO(RTCC1_combo   , LALT(KC_F4)) , // if this works well, consider removing from escape key.
    [RTCC2]  = COMBO(RTCC2_combo   , OSL(_FUNCTIONS))  ,
};

#endif


// -------------------------------------------------------------------------------------------------------    
//   PER KEY TAPPING TERMS
// -------------------------------------------------------------------------------------------------------   

#ifdef TAPPING_TERM_PER_KEY

uint16_t get_tapping_term(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case OSM_SFT:
        case OSM_CTL:
        case OSM_ALT:
            return TAPPING_TERM/2;
        default:
            return TAPPING_TERM;
    }
}

#endif

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
     TD_BLO  ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,QK_RBT  ,                                            QK_RBT  ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,TD_BLO  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_INS  ,XXXXXXX ,KC_F1   ,KC_F2   ,KC_F10  ,XXXXXXX ,KC_TAB  ,                          OSM_RLT ,XXXXXXX ,KC_F10  ,KC_F2   ,KC_F1   ,XXXXXXX ,KC_DEL  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     CAPxF22 ,XXXXXXX ,SW_HAND ,TO_QWER ,TO_KIYUB,XXXXXXX ,KC_ENT  ,                          TD_ESC  ,XXXXXXX ,TO_KIYUB,TO_QWER ,SW_HAND ,XXXXXXX ,FNC_LxP ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     SH_OS   ,XXXXXXX ,XXXXXXX ,AS_OFF  ,AS_ON   ,XXXXXXX ,OSM_ALT ,OSM_ALT ,        TD_APP  ,OSM_GUI ,XXXXXXX ,AS_ON   ,AS_OFF  ,XXXXXXX ,XXXXXXX ,SH_OS   ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     TO_BASE ,KC_SCRL ,KC_PSCR ,OSM_MEH ,     SYM_L   ,    OSM_SFT ,OSM_CTL ,        KC_BSPC ,KC_SPC  ,    NAV_LxT ,     TG_MOSE ,TD_TOP  ,KC_NUM  ,TO_BASE
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),


#else
//VANILLA
  [_BASE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,                                            XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_INS  ,XXXXXXX ,KC_F1   ,KC_F2   ,KC_F10  ,XXXXXXX ,KC_TAB  ,                          KC_RALT ,XXXXXXX ,KC_F10  ,KC_F2   ,KC_F1   ,XXXXXXX ,KC_DEL  ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_EXLM ,XXXXXXX ,SH_TG   ,TO_QWER ,TO_BEAK ,QK_RBT  ,KC_ENT  ,                          KC_ESC  ,QK_RBT  ,TO_BEAK ,TO_QWER ,SH_TG   ,XXXXXXX ,KC_QUES ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_CAPS ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_LALT ,KC_LALT ,        KC_APP  ,KC_RGUI ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,XXXXXXX ,KC_PAUS ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     TO_BASE ,KC_SCRL ,KC_PSCR ,OSM_MEH ,     SYM_LV  ,    KC_LSFT ,KC_LCTL ,        KC_BSPC ,KC_SPC  ,    AxN_L   ,     TG_MOSE ,TD_TOP  ,KC_NUM  ,TO_BASE
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
#endif



      [_NO_DELAY_OVERLAY] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          KC_RALT ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          KC_ESC  ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,KC_LALT ,KC_LALT ,        _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     SYM_LV  ,    KC_LSFT ,KC_LCTL ,        _______ ,_______ ,    AxN_L   ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),    

      [_GAMING_OVERLAY] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,KC_PPLS ,                          KC_PMNS ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                          KC_ESC  ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,KC_LALT ,KC_LALT ,        _______ ,QK_LOCK ,_______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     KC_RALT ,    KC_LSFT ,KC_LCTL ,        _______ ,_______ ,    KC_TAB  ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),    
  
  
  
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //     ALPHABET BASE LAYERS           ALPHABET BASE LAYERS            ALPHABET BASE LAYERS            ALPHABET BASE LAYERS            ALPHABET BASE LAYERS  
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  
    [_KIYUBI] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,KC_1    ,KC_2    ,KC_3    ,KC_4    ,KC_5    ,                                            KC_6    ,KC_7    ,KC_8    ,KC_9    ,KC_0    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,QUOxRMK ,KC_Y    ,KC_O    ,KC_F    ,SCLxGRV ,_______ ,                          _______ ,KC_V    ,KC_C    ,KC_L    ,KC_P    ,CMMxDQO ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_H    ,KC_I    ,KC_E    ,KC_A    ,KC_U    ,_______ ,                          _______ ,KC_D    ,KC_S    ,KC_T    ,KC_N    ,KC_R    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_Q    ,KC_X    ,DOTxAT  ,KC_K    ,KC_Z    ,_______ ,_______ ,        _______ ,_______ ,KC_W    ,KC_G    ,KC_M    ,KC_B    ,KC_J    ,_______ ,
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
     _______ ,KC_PPLS ,KC_LABK ,KC_RABK ,KC_PERC ,KC_BSLS ,_______ ,_______ ,        _______ ,_______ ,KC_PSLS ,KC_RCBR ,KC_RPRN ,KC_RBRC ,KC_BSLS ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,KC_UNDS ,    _______ ,     _______ ,_______ ,_______ ,_______ 
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),

  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    FUNCTIONS LAYER                FUNCTIONS LAYER                FUNCTIONS LAYER                FUNCTIONS LAYER                FUNCTIONS LAYER                
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
 
       [_FUNCTIONS] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_F10  ,KC_F7   ,KC_F4   ,KC_F1   ,_______ ,_______ ,                          _______ ,_______ ,KC_F13  ,KC_F16  ,KC_F19  ,KC_F22  ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_F11  ,KC_F8   ,KC_F5   ,KC_F2   ,_______ ,_______ ,                          _______ ,_______ ,KC_F14  ,KC_F17  ,KC_F20  ,KC_F23  ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_F12  ,KC_F9   ,KC_F6   ,KC_F3   ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,KC_F15  ,KC_F18  ,KC_F21  ,KC_F24  ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
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
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,KC_P7   ,KC_P8   ,KC_P9   ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_PGUP ,KC_UP   ,KC_PGDN ,KCyREDO ,_______ ,                          _______ ,KC_PMNS ,KC_P4   ,KC_P5   ,KC_P6   ,KC_PSLS ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_LEFT ,KC_DOWN ,KC_RGHT ,KCzUNDO ,_______ ,                          _______ ,KC_PPLS ,KC_P1   ,KC_P2   ,KC_P3   ,KC_PAST ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCxCUT_ ,KCcCOPY ,KCvPSTE ,KCdDUP_ ,_______ ,_______ ,        _______ ,_______ ,CMMxDQO ,KC_P0   ,KC_P0   ,KC_PDOT ,KC_PENT ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
   
  
      [_MOUSE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_HOME ,KC_MS_U ,KC_END  ,KCyREDO ,_______ ,                          _______ ,KC_PMNS ,KC_WH_L ,KC_WH_R ,KC_WH_U ,KC_ACL1 ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_MS_L ,KC_MS_D ,KC_MS_R ,KCzUNDO ,_______ ,                          _______ ,KC_PPLS ,KC_BTN1 ,KC_BTN2 ,KC_WH_D ,KC_ACL2 ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCxCUT_ ,KCcCOPY ,KCvPSTE ,KCdDUP_ ,_______ ,_______ ,        _______ ,_______ ,_______ ,KC_BTN3 ,KC_BTN4 ,KC_BTN5 ,KC_ACL0 ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),  
  
  

  
};



// -------------------------------------------------------------------------------------------------------    
//   METHODS
// -------------------------------------------------------------------------------------------------------

//void keyboard_post_init_user(void) {} // KEEB STARTUP 


bool is_alpha_layer(uint16_t keycode){
    return 
           keycode == TO_KIYUB 
        || keycode == TO_QWER ;
}

// used to keep leds lit when the state is temporarily active after quick tap
void matrix_scan_user(void) {  
    set_led_off;
  
    if( layer_state & 
		(
			LAYER_CODE(_SYMB) |
			LAYER_CODE(_ARROW_N_NUMBERS) |
			LAYER_CODE(_FUNCTIONS)
		) 
	) red_led_on;

    if(swap_hands != leftDominantMode) grn_led_on;
    
    if(layer_state & LAYER_CODE(_MOUSE)) ylw_led_on;   
}


bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  
  if(is_alpha_layer(keycode)){
    if (record->event.pressed) {
        blu_led_on; 
    }
    return true;
  }
      
  // ensure led lights up on quick tap
  if(keycode == TG_MOSE ||
#ifdef ADVANCED_BASE_LAYOUT
     keycode == SYM_L || keycode == NAV_LxT || keycode == FNC_LxP
#else
     keycode == SYM_LV || keycode == AxN_L
#endif
  ){
    if (record->event.pressed) {
        red_led_on; 
    }
    //return true;
  }

  // check shift state
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

    case DOTxAT:
        SHIFT_MOD(KC_DOT, KC_AT,record);
        return false;     

    case SCLxGRV:
		SHIFT_MOD(KC_SCLN, KC_GRV,record);
		return false;     

    case QUOxRMK:
        SHIFT_MOD_MARK(KC_QUOT, record);
            return false;  
    
    case SW_HAND:
        SWAP_DOMINANT_HAND(record);
        return false;
          
    case TO_BASE:
		if (record->event.pressed)
			go_to_base_reset(); 
		return true;   
	
	case CAPxF22: 
		if (record->tap.count && record->event.pressed) {
			return true; // normal processing of tap keycode
		} else if (record->event.pressed) {
			register_code16(KC_F22); // intercept hold function
			return false;
		}
		//normal processing of key release
		unregister_code16(KC_F22);
		return true; 
		
	case SYM_L:
		if (!record->event.pressed){
			unregister_code16(KC_F24);
			pseudo_layer_hack &= ~LAYER_CODE(_SYMB);
			layer_state |= pseudo_layer_hack;
		}
		else
		{
			pseudo_layer_hack |= LAYER_CODE(_SYMB);
			if(pseudo_layer_hack & LAYER_CODE(_ARROW_N_NUMBERS))
			{
				register_code16(KC_F24);
				layer_off(_ARROW_N_NUMBERS); 
				return false;
			}
		}
		return true;
	case NAV_LxT:
		if (!record->event.pressed){
			unregister_code16(KC_F24);
			pseudo_layer_hack &= ~LAYER_CODE(_ARROW_N_NUMBERS);
			layer_state |= pseudo_layer_hack;
			
			if (layer_state & LAYER_CODE(_SYMB))
				set_oneshot_layer(_SYMB, ONESHOT_PRESSED);
		}
		else
		{
			pseudo_layer_hack |= LAYER_CODE(_ARROW_N_NUMBERS);
			if(pseudo_layer_hack & LAYER_CODE(_SYMB))
			{	
				register_code16(KC_F24);
				clear_oneshot_layer_state(_SYMB);
				layer_off(_SYMB);
				return false;
			}
		}
		return true;
		
  }
  return true;
};
