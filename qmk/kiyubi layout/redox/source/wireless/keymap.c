#include QMK_KEYBOARD_H

// LEDs are used to indicate layer transitions/usage
// 	comment the following line if the keeb has no LEDs
#define KEEB_HAS_LEDS
#define CHANGE_LED_CODES





// -------------------------------------------------------------------------------------------------------    
//   CUSTOM BEHAVIORS  
// -------------------------------------------------------------------------------------------------------    
//#define ENABLE_DOMINANT_HAND_SWAP
#ifdef ENABLE_DOMINANT_HAND_SWAP

void SWAP_DOMINANT_HAND(keyrecord_t *record){
    if (record->event.pressed ) { 
      leftDominantMode=!leftDominantMode;  
      swap_hands=!swap_hands;
    }
}

#else
#define SW_HAND  XXXXXXX
#endif
//-----------------------------------------------------------------
#if 1
layer_state_t pseudo_layer_hack = 0;
// pseudo_layer_hack keeps track of the NAVIGATION & SYMBOL states
// in order to implement a functionality similar to tri-layer.
// when both mods are pressed, neither layer is active and 
// "normal" key is send instead ( F24 as of last implementation ) 


#endif 

// -------------------------------------------------------------------------------------------------------    
//   LEDs colors    
// -------------------------------------------------------------------------------------------------------    
#if 1

#if	!defined(KEEB_HAS_LEDS) || defined(CHANGE_LED_CODES)

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

#endif

#ifdef KEEB_HAS_LEDS
#ifdef CHANGE_LED_CODES
//notes regarding leds on my keeb
// default set red => lights green
// default set green => lights red
// default set blue => lights yellow
// added a new code to use the additional blue light.

// leds order: B R Y G

#define red_led_off   PORTD |= (1<<1)
#define red_led_on    PORTD &= ~(1<<1)
#define blu_led_off   PORTD |= 1
#define blu_led_on    PORTD &= ~(1)
#define ylw_led_off   PORTF |= (1<<4)
#define ylw_led_on    PORTF &= ~(1<<4)
#define grn_led_off   PORTF |= (1<<5)
#define grn_led_on    PORTF &= ~(1<<5)

#endif //CHANGE_LED_CODES
#else // ! KEEB_HAS_LEDS

#define red_led_off   
#define red_led_on    
#define blu_led_off   
#define blu_led_on    
#define ylw_led_off   
#define ylw_led_on    
#define grn_led_off   
#define grn_led_on    
	
#endif // KEEB_HAS_LEDS

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

#define _SYMB 4
//symbols layer

#define _FUNCTIONS 5
// all F keys, 1 to 24

// - - - - - - - - - - - -
// top row overlays
//#define _TOP_NUMBERS 5   // already in kiyubi & qwerty layers
#define _TOP_MEDIA 6
// - - - - - - - - - - - -

#define _MOUSE 3
//navigation using mouse, home, end, etc... 
//also has shortcuts for copy, paste, and similar...

#define _ARROW_N_NUMBERS 7
//navigation using arrows, home, end, etc... 
//also has shortcuts for copy, paste, and similar...
//also has a numpad on the right half

#define _NO_DELAY_OVERLAY 8
// a layer that removes One Shots and the like from the base layer
// useful to spam mod keys without triggering one shots and have no delays on key presses

#define _GAMING_OVERLAY 9
// similar to no delay layer but without thumb layers and w/ some key code swaps and with a QK_LOCK key

#endif

// -------------------------------------------------------------------------------------------------------    
//   CUSTOM KEY ALIASES AND CUSTOM KEYCODES
// -------------------------------------------------------------------------------------------------------   
#if 1


enum custom_keycodes {
  QMKBEST = SAFE_RANGE, 

#ifdef ENABLE_DOMINANT_HAND_SWAP
  SW_HAND,
#endif
};

// Shortcuts to make keymap more readable
#define TESTMCR QMKBEST

#define SYM_LV   MO(_SYMB)
#define SYM_L   OSL(_SYMB)
#define AxN_L   MO(_ARROW_N_NUMBERS)
#define MED_L   TG(_TOP_MEDIA)
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

#define ALT_ENT LALT(KC_ENT)

#define SYM_LxE LT(_SYMB, KC_ENT)
#define NAV_LxT LT(_ARROW_N_NUMBERS, KC_TAB)

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
//		KEY OVERRIDES

const key_override_t dot_at_override = ko_make_with_layers(MOD_MASK_SHIFT, KC_DOT, KC_AT, 1<<_KIYUBI);
const key_override_t comma_quotes_override = ko_make_with_layers(MOD_MASK_SHIFT, KC_COMM, KC_DQUO, 1<<_KIYUBI);
const key_override_t semic_grave_override = ko_make_with_layers(MOD_MASK_SHIFT, KC_SCLN, KC_GRV, 1<<_KIYUBI);
//const key_override_t apos_quotes = ko_make_basic(MOD_MASK_SHIFT, KC_QUOT, );
const key_override_t volume_up_dn_override = ko_make_basic(MOD_MASK_SHIFT, KC_VOLU, KC_VOLD);
const key_override_t brightness_up_dn_override = ko_make_basic(MOD_MASK_SHIFT, KC_BRIU, KC_BRID);
const key_override_t media_nxt_prv_override = ko_make_basic(MOD_MASK_SHIFT, KC_MNXT, KC_MPRV);
//const key_override_t pc_sleep_wake_override = ko_make_basic(MOD_MASK_SHIFT, KC_SLEP, KC_WAKE);
const key_override_t mute_stop_override = ko_make_basic(MOD_MASK_SHIFT, KC_MUTE, KC_MSTP);


// This globally defines all key overrides to be used
const key_override_t **key_overrides = (const key_override_t *[]){
    &dot_at_override,
    &comma_quotes_override,
	&semic_grave_override,
	
	&volume_up_dn_override,
	&brightness_up_dn_override,
	&media_nxt_prv_override,
	//&pc_sleep_wake_override,
	&mute_stop_override,
    
	NULL // Null terminate the array of overrides!
};

// - - - - - - - - - - - - - - - - - -
//     TAP DANCE 

enum   {
  CT_GUI=0,
  CT_APP,
  //CT_TOP, // top row overlay
  CT_BLO, // "base" layer overlay
  TD_ESC_ALTF4, // escape -> Alt + F4
};


void soft_reset(void){
  clear_oneshot_mods();
  clear_mods();
  clear_oneshot_locked_mods();
  reset_oneshot_layer();
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
 [CT_BLO] = ACTION_TAP_DANCE_FN (dance_base_layer_overlay),
 [TD_ESC_ALTF4] = ACTION_TAP_DANCE_DOUBLE(KC_ESC, LALT(KC_F4)),
 };

#define TD_APP TD(CT_APP)
//#define TD_TOP TD(CT_TOP)   // no longer used; to be removed
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

PWROFF, // escape + ralt on FUNC layer -> powers off pc ( implemented as combo to prevent misfires )
};

const uint16_t PROGMEM OSMSA_combo[] = {OSM_SFT, OSM_ALT, COMBO_END};
const uint16_t PROGMEM OSMSC_combo[] = {OSM_SFT, OSM_CTL, COMBO_END};
const uint16_t PROGMEM OSMCA_combo[] = {OSM_CTL, OSM_ALT, COMBO_END};
const uint16_t PROGMEM OSMSCA_combo[] = {OSM_SFT, OSM_CTL, OSM_ALT, COMBO_END};
const uint16_t PROGMEM RTCC1_combo[] = {KC_BSPC, TD_APP, COMBO_END};
const uint16_t PROGMEM RTCC2_combo[] = {OSM_GUI, KC_SPC, COMBO_END};
//const uint16_t PROGMEM F24C_combo[] = {SYM_L, NAV_LxT, COMBO_END}; // pseudo, not a combo, but similar
const uint16_t PROGMEM PWROFF_combo[] = {KC_SYRQ, TD_ESC, COMBO_END};
combo_t key_combos[] = {
    [OSMSA]  = COMBO(OSMSA_combo   , SFT_ALT)  ,
    [OSMSC]  = COMBO(OSMSC_combo   , SFT_CTL)  ,
    [OSMCA]  = COMBO(OSMCA_combo   , CTL_ALT)  ,
    [OSMSCA] = COMBO(OSMSCA_combo  , OSM_MEH)  ,
    [RTCC1]  = COMBO(RTCC1_combo   , LALT(KC_F4)) , // if this works well, consider removing from escape key.
    [RTCC2]  = COMBO(RTCC2_combo   , OSL(_FUNCTIONS))  ,
	
    [PWROFF]  = COMBO(PWROFF_combo   , KC_PWR)  ,
};



// function below is untested; KC_SYRQ is used in FUNC layer for the POWEROFF combo, so there is not need to check layer when comboing
//bool combo_should_trigger(uint16_t combo_index, combo_t *combo, uint16_t keycode, keyrecord_t *record) 
//{return (PWROFF != combo_index) || (is_oneshot_layer_active() && get_oneshot_layer() == _FUNCTIONS);}

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
     CAPxF22 ,XXXXXXX ,SW_HAND ,TO_QWER ,TO_KIYUB,XXXXXXX ,KC_ENT  ,                          TD_ESC  ,XXXXXXX ,TO_KIYUB,TO_QWER ,SW_HAND ,XXXXXXX ,KC_PAUS ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     SH_OS   ,XXXXXXX ,XXXXXXX ,AS_OFF  ,AS_ON   ,XXXXXXX ,OSM_ALT ,OSM_ALT ,        TD_APP  ,OSM_GUI ,XXXXXXX ,AS_ON   ,AS_OFF  ,XXXXXXX ,XXXXXXX ,SH_OS   ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     TO_BASE ,KC_SCRL ,KC_PSCR ,OSM_MEH ,     SYM_L   ,    OSM_SFT ,OSM_CTL ,        KC_BSPC ,KC_SPC  ,    NAV_LxT ,     TG_MOSE ,MED_L   ,KC_NUM  ,TO_BASE
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
     TO_BASE ,KC_SCRL ,KC_PSCR ,OSM_MEH ,     SYM_LV  ,    KC_LSFT ,KC_LCTL ,        KC_BSPC ,KC_SPC  ,    AxN_L   ,     TG_MOSE ,MED_L   ,KC_NUM  ,TO_BASE
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
     _______ ,KC_QUOT ,KC_Y    ,KC_O    ,KC_F    ,KC_SCLN ,_______ ,                          _______ ,KC_V    ,KC_C    ,KC_L    ,KC_P    ,KC_COMM ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_H    ,KC_I    ,KC_E    ,KC_A    ,KC_U    ,_______ ,                          _______ ,KC_D    ,KC_S    ,KC_T    ,KC_N    ,KC_R    ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_Q    ,KC_X    ,KC_DOT  ,KC_K    ,KC_Z    ,_______ ,_______ ,        _______ ,_______ ,KC_W    ,KC_G    ,KC_M    ,KC_B    ,KC_J    ,_______ ,
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
     _______ ,KC_F10  ,KC_F7   ,KC_F4   ,KC_F1   ,_______ ,_______ ,                          KC_SYRQ ,_______ ,KC_F13  ,KC_F16  ,KC_F19  ,KC_F22  ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WAKE ,KC_F11  ,KC_F8   ,KC_F5   ,KC_F2   ,_______ ,_______ ,                          _______ ,_______ ,KC_F14  ,KC_F17  ,KC_F20  ,KC_F23  ,KC_SLEP ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_F12  ,KC_F9   ,KC_F6   ,KC_F3   ,_______ ,_______ ,_______ ,        _______ ,_______ ,_______ ,KC_F15  ,KC_F18  ,KC_F21  ,KC_F24  ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),
 
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------
  //    TOP ROW OVERLAYS                TOP ROW OVERLAYS            TOP ROW OVERLAYS            TOP ROW OVERLAYS            TOP ROW OVERLAYS
  // ------------------------------------------------------------------------------------------------------------------------------------------------------------

      [_TOP_MEDIA] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,KC_MUTE ,KC_MNXT ,KC_VOLU ,KC_BRIU ,_______ ,                                            _______ ,KC_BRID ,KC_VOLD ,KC_MPRV ,KC_MSTP ,_______ ,
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
  
        [_MOUSE] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,_______ ,_______ ,_______ ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_PGUP ,KC_MS_U ,KC_PGDN ,KCyREDO ,_______ ,                          _______ ,KC_PMNS ,KC_WH_L ,KC_WH_R ,KC_WH_U ,KC_ACL1 ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_MS_L ,KC_MS_D ,KC_MS_R ,KCzUNDO ,_______ ,                          _______ ,KC_PPLS ,KC_BTN1 ,KC_BTN2 ,KC_WH_D ,KC_ACL2 ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCxCUT_ ,KCcCOPY ,KCvPSTE ,KCdDUP_ ,_______ ,_______ ,        _______ ,_______ ,_______ ,KC_BTN3 ,KC_BTN4 ,KC_BTN5 ,KC_ACL0 ,_______ ,
  //├────────┼────────┼────────┼────────┼────┬───┴────┬───┼────────┼────────┤       ├────────┼────────┼───┬────┴───┬────┼────────┼────────┼────────┼────────┤
     _______ ,_______ ,_______ ,_______ ,     _______ ,    _______ ,_______ ,        _______ ,_______ ,    _______ ,     _______ ,_______ ,_______ ,_______
  //└────────┴────────┴────────┴────────┘    └────────┘   └────────┴────────┘       └────────┴────────┘   └────────┘    └────────┴────────┴────────┴────────┘
  ),  
  
    [_ARROW_N_NUMBERS] = LAYOUT(
  //┌────────┬────────┬────────┬────────┬────────┬────────┐                                           ┌────────┬────────┬────────┬────────┬────────┬────────┐
     _______ ,_______ ,GOTO1__ ,KCfFIND ,KChRPLC ,GOTO2__ ,                                            _______ ,KC_P7   ,KC_P8   ,KC_P9   ,_______ ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┐                         ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,GOTO2__ ,KC_PGUP ,KC_UP   ,KC_PGDN ,KCyREDO ,_______ ,                          _______ ,KC_PMNS ,KC_P4   ,KC_P5   ,KC_P6   ,KC_PSLS ,_______ ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┤                         ├────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     KC_WBAK ,KC_HOME ,KC_LEFT ,KC_DOWN ,KC_RGHT ,KCzUNDO ,_______ ,                          _______ ,KC_PPLS ,KC_P1   ,KC_P2   ,KC_P3   ,KC_PAST ,KC_WFWD ,
  //├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┐       ┌────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
     _______ ,KC_END  ,KCxCUT_ ,KCcCOPY ,KCvPSTE ,KCdDUP_ ,_______ ,_______ ,        _______ ,_______ ,KC_COMM ,KC_P0   ,KC_P0   ,KC_PDOT ,KC_PENT ,_______ ,
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


#ifdef KEEB_HAS_LEDS
void matrix_scan_user(void) { // used to keep leds lit when the state is temporarily active after quick tap
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
#endif


bool process_record_user(uint16_t keycode, keyrecord_t *record) {
#ifdef KEEB_HAS_LEDS  
  if(is_alpha_layer(keycode)){
    if (record->event.pressed) {
        blu_led_on; 
    }
    return true;
  }
      
  // ensure led lights up on quick tap
  if(keycode == TG_MOSE ||
#ifdef ADVANCED_BASE_LAYOUT
     keycode == SYM_L || keycode == NAV_LxT 
#else
     keycode == SYM_LV || keycode == AxN_L
#endif
  ){
    if (record->event.pressed) {
        red_led_on; 
    }
    //return true;
  }
#endif //KEEB_HAS_LEDS  
  
  switch (keycode) {
     
#ifdef ENABLE_DOMINANT_HAND_SWAP
    case SW_HAND:
        SWAP_DOMINANT_HAND(record);
        return false;
#endif //ENABLE_DOMINANT_HAND_SWAP
          
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

#ifdef KEEB_HAS_LEDS
	case MED_L:
		blu_led_on;
		if((layer_state & LAYER_CODE(_TOP_MEDIA)) == 0){
			red_led_on; ylw_led_on;
		}
#endif

  }
  return true;
};
