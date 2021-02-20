# Caps

Adds behaviours related to letters' case.



## Function table

| `Input` | Function |
|-|-|
| `Shift + CapsLock` | On selected text - capitalizes all words that start a sentence with respect to the selection scope|
| `Ctrl + CapsLock` | On selected text or on word behind cursor - Converts all letters to uppercase|
| `Alt + CapsLock` | On selected text or on word behind cursor - Converts all letters to lowercase|
| `Shift + Ctrl + CapsLock` | Converts all letters behind the cursor to uppercase (does nothing with text selection, will execute the same as `Ctrl + CapsLock`)|
| `Shift + Alt + CapsLock` | Converts all letters behind the cursor to lowercase (does nothing with text selection, will execute the same as `Alt + CapsLock`)|
| `CapsLock + Pause` | Toggle Lazy Mode |



## Lazy Mode

Will auto capitalize words and add spaces after punctuation.

You can check whether Lazy Mode is active or not by the script's icon.

Lazy Mode options can be tweaked arround line 144.

```
; --- Lazy Mode Options ---
 x := True        ; start off script with an assumed capital (true)
 R := True        ; always capitalize after typing return
 E := "{Return}"  ; list of endkeys to trigger capitalizing
 C := True        ; add space after comma
; --- ---  --- ---  --- ---
```

## Credits

Icons made by <a href="https://www.flaticon.com/authors/smashicons" title="Smashicons">Smashicons</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>