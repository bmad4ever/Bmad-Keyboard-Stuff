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

You can check whether Auto Mode is active or not by the script's icon.

Auto Mode options can be tweaked around line 206.

```
; --- Auto Mode Options ---
 x := True        ; start off script with an assumed capital (true)
 R := True        ; always capitalize after typing return
 E := "{Return}"  ; list of end-keys to trigger capitalizing
 C := True        ; add space after comma
 D := True        ; add space after colon or semicolon
; --- ---  --- ---  --- ---
```


## Programming Commands

Commands to convert between different programming conventions.

In order to use the commands listed below, ProgrammerCommands, on line 111, should be set to True.

```
ProgrammerCommands := True
```

| `Command` | Function |
|-|-|
| `Ctrl + Insert` | On selected text or on word behind cursor - converts snake_case into camelCase (can also convert from kebab-case by using text selection). When already using camelCase, converts it into PascalCase and vice versa. |
| `Alt + Insert` | On selected text or on word behind cursor - converts camelCase into snake_case (can also convert from kebab-case by using text selection) |
| `Ctrl + Alt + Insert` | On selected text or on word behind cursor - converts any case into kebab-case |

## Credits

Icons made by <a href="https://www.flaticon.com/authors/smashicons" title="Smashicons">Smashicons</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>