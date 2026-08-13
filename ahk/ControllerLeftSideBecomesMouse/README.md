# ControllerLeftSideBecomesMouse

AutoHotkey script that turns a DualShock 4 (or any DirectInput joystick) held in the left hand into a mouse plus keyboard layer. Left stick = cursor, right stick = scroll, buttons = keys/actions. Two hold-to-activate special states replace the normal layout while active.

Requires: AutoHotkey v1, a DirectInput-capable gamepad in "gamepad mode" (many turbo controllers need TURBO + Start/PS at power-on).

Face buttons: **□** = 1, **✕** = 2, **◯** = 3, **△** = 4. Shoulders: **L1** = 5, **R1** = 6, **L2** = 7, **R2** = 8. Sticks press: **L3** = 11, **R3** = 12. Center: **Share** = 9, **Options** = 10. **PS** = 13, **Pad** = 14.

---

## Normal state (default)

| Control            | Action                                            |
|--------------------|---------------------------------------------------|
| Left stick         | Move cursor (relative injection)                  |
| Right stick        | Scroll wheel (vertical); Shift + mostly-horizontal = horizontal scroll |
| □ (1)              | **Ctrl** (held while pressed)                     |
| ✕ (2)              | Enter                                             |
| ◯ (3)              | Esc                                               |
| △ (4)              | Hold = **Special State 1** (window management)    |
| L1 (5)             | Left click                                        |
| R1 (6)             | Zoom in (Ctrl + WheelUp, repeated while held)     |
| L2 (7)             | Right click                                       |
| R2 (8)             | Zoom out (Ctrl + WheelDown, repeated while held)  |
| Share (9)          | Previous virtual desktop (Win+Ctrl+Left)          |
| Options (10)       | Next virtual desktop (Win+Ctrl+Right)             |
| L3 (11)            | Shift+Tab                                         |
| R3 (12)            | Tab                                               |
| PS (13)            | Show desktop (Win+D)                              |
| Pad (14)           | Hold = **Special State 2** (clipboard/arrows)     |
| D-pad up/down      | Sensitivity up/down (5 levels: x0.4 – x2.7)       |
| D-pad left/right   | Browser back / forward (Alt+Left / Alt+Right)     |

---

## Special State 1 (hold △/4) — window management

Everything from the normal state is disabled while active.

| Control            | Action                                            |
|--------------------|---------------------------------------------------|
| Left stick         | Dock window by sector: 8 zones (maximize, minimize, half-left/right, 4 corners) |
| D-pad up           | Move window to next monitor                       |
| D-pad down         | Move window to previous monitor                   |
| D-pad left         | Alt+Tab                                           |
| D-pad right        | Alt+Shift+Tab                                     |
| ◯ (3)              | Win+Tab (task view)                               |
| L1 (5)             | F11 (borderless fullscreen toggle)                |
| R1 (6)             | Roll-up / roll-down toggle (title bar height)     |
| Share (9)          | Alt+F4                                            |
| Options (10)       | Explorer view toggle (info <-> small icons)       |
| L3 (11)            | Center window on its monitor                      |
| L2 / R2 triggers   | Volume down / up (speed follows pull depth)       |

---

## Special State 2 (hold Pad/14) — clipboard & arrows

Everything from the normal state is disabled while active.

| Control            | Action                                            |
|--------------------|---------------------------------------------------|
| □ (1)              | Ctrl+C                                            |
| ✕ (2)              | Ctrl+X                                            |
| ◯ (3)              | Delete                                            |
| △ (4)              | Ctrl+V                                            |
| L1 (5)             | **Ctrl** (held while pressed)                     |
| R1 (6)             | Ctrl+Y                                            |
| L2 (7)             | Ctrl+Z                                            |
| R2 (8)             | Ctrl+Shift+Z (redo)                               |
| Options (10)       | **AltGr** (Right Alt, held while pressed)         |
| L3 (11) / R3 (12)  | **Space** (held while pressed)                    |
| Left / right stick | Arrow keys, 8 cardinals (diagonals press both keys). Held while the stick is deflected; repeat rate scales with stick magnitude (min 1/sec at dead-zone edge, max 50/sec at full deflection). Left stick takes priority if both are deflected |
| D-pad down         | Alt+Enter                                         |

---

## Configuration

All settings live at the top of `ps-mouse.ahk` under `; ============ CONFIG ============`:

- `Sensitivity` / `SensBase` / `SensTable` — cursor speed and the 5 selectable levels
- `DeadZone` — left-stick center dead zone (0–50 percent)
- `SpecStickDead` — special-state stick dead zone (higher than `DeadZone`)
- `RepeatMinSpeed` / `RepeatMaxSpeed` — state-2 arrow repeat rate at dead-zone edge vs full deflection
- `*Button` — physical button numbers for each action
- `ScrollSpeed`, `ScrollReverse` — right-stick scroll behaviour
- `ZoomSpeed` — zoom step rate while a zoom button is held
- `VolThresh`, `VolMaxStep` — trigger-based volume control
- `RightXOffset` / `RightYOffset` — `joyGetPosEx` offsets for right-stick axes
- `DebugMode` — 1 = live axis/button readout tooltip
