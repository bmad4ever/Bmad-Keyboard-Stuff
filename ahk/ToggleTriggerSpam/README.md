# Toggle-Trigger-Spam (TTS)

The script allows to trigger <b>SPAM MODE</b> using a user defined <b>toggle key</b>, on <b>line 47</b>.

```
*$Shift::
```


When in <b>SPAM MODE</b>, if any <b>trigger key</b> is pressed then the key defined as <b>spam key</b> is also sent.

<b>Trigger keys</b> are defined on <b>line 38</b>.

```
TriggerKeys := ["w","a","s","d","LCtrl","Space"] 
```

 The <b>spam key</b> is defined in line <b>line 41</b>.

```
SpamKey := "Shift"
```

 Note that despite the <b>spam key</b> being set to the same key as the <b>toggle key</b> by default it is possible to assign two different keys for each.

The <b>toggle key</b> does not send the toggle key code when pressed. This can be changed by adding a Send command on the toggle function.


## Usage

The primary purpose of this script is to be used in games and interactive applications that have a hold button functionality for movement or camera control but do not have a toggle option, or, do have a toggle but the toggle has some undesired "neutral behavior" (when not pressing other keys).

Example:
- In a game, transform the hold key to sprint/boost/turbo functionality to a toggle;
- In the example above, if the game also has a toggle funtionality option but this results in undesired movement or actions when nothing is being pressed. Set the game funtionality to hold and use this script instead.




