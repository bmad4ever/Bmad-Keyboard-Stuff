# <img src="sc.ico" alt="icon" width="32" height="32"/> &nbsp; Selection Commands  


### Configuration : The key bindings can be edited in the KEY MAPS section of script, at the top of the file.

**By default, all commands require pressing the key defined by `trigger`, set to `F22`.**


## List of Commands 

- **Select Word**
    - default key binding : <kbd>trigger</kbd> ( on release )
    - selects the word under the cursor.
    - can also select a number with a single decimal point, if the dicimal point is defined with a dot, i.e., won't work with commas. 
- **Go To Open**
    - default key binding : <kbd>trigger</kbd> + <kbd>Tab</kbd>
    - moves cursor to the first open parenthesis, bracket, or curly bracket - `( [ {` - on the current line.
    - if any of the above symbols is behind the cursor, then it moves to the next one on the line; or back to the first again if there are none to the right.
    - if the line exceeds `max_number_of_chars_in_clipboard` (512 by default), then the operation is canceled and the cursor will be set at the beginning of the line with it selected.
- **Select Till Closed**
    - default key binding : <kbd>trigger</kbd> + <kbd>Space</kbd>
    - behavior is similar to GoToOpen, but will also select the content contained within the parenthesis, brackets, or curly brackets.


### AddSelection Commands 

1. **These operations require that a number is selected.**
1. They may behave janky when spammed, so avoid spamming them.
1. There are some inconsistencies and limitations in the current implementation; try to avoid using them when dealing with very large or small numbers, and be mindful that using an operation may output the number in a slightly different format than its reverse operation.

- **AddSelection( 1 , OP_EXP )**
    - default key binding : <kbd>trigger</kbd> + <kbd>o</kbd> ( on release )
    - multiplies the selected number by 10. 
- **AddSelection( -1 , OP_EXP )**
    - default key binding : <kbd>trigger</kbd> + <kbd>e</kbd> ( on release )
    - multiplies the selected number by 0.1. 
- **AddSelection( 1 , OP_ADD_LS )**
    - default key binding : <kbd>trigger</kbd> + <kbd>a</kbd> ( on release )
    - adds 1 in the same units as the rightmost digit. Examples: 0.02 → 0.03 ; 9 → 10
- **AddSelection( -1 , OP_ADD_LS )**
    - default key binding : <kbd>trigger</kbd> + <kbd>i</kbd> ( on release )
    - subtracts 1 in the same units as the rightmost digit. Examples: 0.03 → 0.02 ; 10 → 9
- **AddSelection( 1 , OP_ADD_MS )**
    - default key binding : <kbd>trigger</kbd> + <kbd>y</kbd> ( on release )
    - only implemented for integers.
    - adds 1 in the same units as the leftmost digit. Example: 93 → 103 → 203 
- **AddSelection( -1 , OP_ADD_MS )**
    - default key binding : <kbd>trigger</kbd> + <kbd>f</kbd> ( on release )
    - only implemented for integers.
    - subtracts 1 in the same units as the leftmost digit; except for when it is 1 followed by a 0, in which case subtracts in the following digit units. Examples: 1520 → 520 ; 1020 → 920


### Other Commands

- **Open In FullScreen**
    - default key binding : <kbd>trigger</kbd> + <kbd>Enter</kbd>
    - Will maximize the application after oppening. (may fail if active app changes before the target app opens)
    - If the application is listed in `apps_to_f11`, in the configs, then F11 will be sent. 

- **Clear Line**
    - default key binding : <kbd>trigger</kbd> + <kbd>Backspace</kbd>
    - deletes a entire line.

- **Toggle Suspend**
    - default key binding : <kbd>trigger</kbd> + <kbd>Pause</kbd>
    - suspends this ahk script, or reactivates it if previously suspended. 
