Keyboard named folders such as “redox” or “ergodox” contain documentation and the source code for the layout on the respective keyboard.


The common folder contains modifications to the source qmk firmware ([applied to December's 2023 release](https://github.com/qmk/qmk_firmware/releases/tag/0.23.2)), listed below:
- Hand Swap Behavior was modified to allow reversing a layout "permantly", without reseting to a non-swap state after One Shot swaps (OSs). This allows a left-hand dominant user to use a horizontally reversed layout without removing the OSs funtionality.

To toggle between a normal and reversed layout use the following code:
```
      leftDominantMode=!leftDominantMode;  
      swap_hands=!swap_hands;
```

- ~~One Shot Mods Modifier was modified so that it is possible to tap toggle more than one modifier at the same time. Disclaimer: sometimes may not behave exactly as intended and even when working as intended it may be confusing to work with, so consider whether you really need this functionality before including it in your build.~~