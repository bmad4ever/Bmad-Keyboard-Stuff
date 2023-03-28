# Caps

## Standard commands

Commands to manipulate letters' casing.


| `Command` | Function |
|-|-|
| `Shift + CapsLock` | On selected text or from the cursor position to the beginning of the line - capitalizes all words that start a sentence and the first word of the selection/line|
| `Ctrl + CapsLock` | On selected text or on word behind cursor - Converts all letters to uppercase|
| `Alt + CapsLock` | On selected text or on word behind cursor - Converts all letters to lowercase|
| `Shift + Ctrl + CapsLock` | Converts all letters behind the cursor to uppercase (does nothing with text selection, will execute the same as `Ctrl + CapsLock`)|
| `Shift + Alt + CapsLock` | Converts all letters behind the cursor to lowercase (does nothing with text selection, will execute the same as `Alt + CapsLock`)|
| `Ctrl + Alt + CapsLock` | On selected text or on word behind cursor - capitalizes word(s) |
| `Shift + Ctrl + Alt + CapsLock` | Capitalizes all words behind the cursor |
| `CapsLock + AltGr` | Toggle Auto Mode |



## Auto Mode

Will auto capitalize words and add spaces after punctuation.

For the auto-capitalization to occur, you must press a character after the punctuation, and a space will be added automatically. 
If you add the space manually, the next character won't be capitalized; spaces should be used when dealing with exceptions where an otherwise expected capitalization is not desired.

You can check whether Auto Mode is active or not by the script's icon.

Additional settings may be tweaked at the "User config." section of the script.

## Programming Commands

Commands to convert between different programming conventions. 

In order to use the commands listed below, set ProgrammerCommands to true in the "User config." section of the script.

```
ProgrammerCommands := True
```

| `Command` | Function |
|-|-|
| `Ctrl + Insert` | On selected text or on word behind cursor - converts snake_case into camelCase (can also convert from kebab-case by using text selection). When already using camelCase, converts it into PascalCase and vice versa. |
| `Alt + Insert` | On selected text or on word behind cursor - converts camelCase into snake_case (can also convert from kebab-case by using text selection) |
| `Ctrl + Alt + Insert` | On selected text or on word behind cursor - converts any case into kebab-case |

__________________ 
## <p style="text-align: center;"> Potential Problems and How to  Solve Them  </p>                                                     
__________________ 

### <p style="text-align: center;"> OS Commands </p>
__________________ 

The above codes may coincide with other OS defined commands. 
If you have multiple keyboard layouts or languages, it is likely that you have one such command for swapping between them. 

These commands can usually be changed in the keyboard settings. For example, in MS Windows, you can deactivate these in the "Advanced Keyboard Settings" and use the Windows+Space combination to swap between different layouts/languages. 

__________________ 
### <p style="text-align: center;"> ClipBoard and Programs that use Ctrl+C commands </p> 
__________________ 
In order to edit a selection, the command Ctrl+C is issued to check if there is anything selected (your previous clipboard data is restored afterwards).

However, certain programs use the Ctrl+C combo for certain operations. 
For example, in Visual Studio, Ctrl+C is used to copy the current line when
nothing is selected. 
Therefore the Caps AHK script won't be able to work everywhere.

Instead of deactivating the script completely, you can deactivate some functionalities by adding the problematic programs to the ignore list in 
the "User Config." section of the script. 
By doing this, when working inside the program, operations over selected text or command variations that use the shift modifier will be deactivated.

_______________________________
## Credits

Icons made by <a href="https://www.flaticon.com/authors/smashicons" title="Smashicons">Smashicons</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>