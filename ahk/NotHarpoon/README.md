# <img src="trident.ico" alt="icon" width="32" height="32"/> &nbsp; (Not) Harpoon

### Allows to bind windows to keys for quick navigation; and provides some utilities for window management.


### Configuration : The key bindings can be edited in the KEY MAPS section, at the top of the script file. 


## How to use

Open the window you want to bind and hold the [`trigger`](https://github.com/bmad4ever/Bmad-Keyboard-Stuff/blob/eae08407bc7ac5fbbdda3ff7a59dd3649c353854/ahk/NotHarpoon/NotHarpoon.ahk#L9) key (default is <kbd>F24</kbd>).

While holding <kbd>trigger</kbd>, tap on the [`binder`](https://github.com/bmad4ever/Bmad-Keyboard-Stuff/blob/eae08407bc7ac5fbbdda3ff7a59dd3649c353854/ahk/NotHarpoon/NotHarpoon.ahk#L14) key (default is <kbd>H</kbd>).

Now you can bind the window to any key in the [`harpoon_keys`](https://github.com/bmad4ever/Bmad-Keyboard-Stuff/blob/eae08407bc7ac5fbbdda3ff7a59dd3649c353854/ahk/NotHarpoon/NotHarpoon.ahk#L38) list.

Once the window is deactivated, you can re-activate it by holding <kbd>trigger</kbd> and tapping on the previously assigned key. 

Et voilà, quick window navigation at the tip of your fingers.

### Quick Layout commands

With <kbd>trigger</kbd> held, tap one of the 9 keys in the `layout_keys` to quickly adjust the active window position & dimensions.

For ease of use, I recommend that you set the [`layout_keys`](https://github.com/bmad4ever/Bmad-Keyboard-Stuff/blob/eae08407bc7ac5fbbdda3ff7a59dd3649c353854/ahk/NotHarpoon/NotHarpoon.ahk#L29C2-L29C2) in a 3x3 key grid. For example, in a qwerty keyboard, it could be: `q w e a s d z x c`.



### Additional commands

- **Show Bindings List** : default key binding : <kbd>trigger</kbd> 

- **Clear Bindings**
    - default key binding : <kbd>trigger</kbd> + <kbd>Delete</kbd> 
    - deletes all window-key binds ( windows remain open ).

- **Show All Binded Windows**
    - default key binding : <kbd>trigger</kbd> + <kbd>d</kbd>
    - brings all the binded windows to the front but won't change their prior layout (some may occlude others). 

- **Close Non Binded Windows**
    - default key binding : <kbd>trigger</kbd> + <kbd>CapsLock</kbd> 
    - tries to close all the windows that are not binded, which may prompt a confirmation message instead of closing (e.g. in the case of open unsaved documents).

- **Close Non Binded Windows (force)**
    - default key binding : <kbd>trigger</kbd> + <kbd>F22</kbd> 
    - forcefully terminates all the processes of windows that are not binded.  
