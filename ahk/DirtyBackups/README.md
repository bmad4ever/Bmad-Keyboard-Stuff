# Dirty Backups

A small background utility that lets you send files and clipboard text to a backup folder instantly, using keyboard shortcuts.

---

## Keyboard Shortcuts

> **Note:** F23 is not a physical key on most keyboards. It is meant to be assigned to a spare key using a macro pad, a foot pedal, or a remapping tool. If you are unsure how to do this, ask whoever set up the script for you.

| Shortcut | What it does |
|---|---|
| `F23` | Opens your backup folder in File Explorer |
| `Shift + F23` | Copies the selected file(s) to the backup folder |
| `Ctrl + F23` | Moves the selected file(s) to the backup folder |
| `Alt + F23` | Saves whatever text is on your clipboard as a new file |

**Copy vs. Move:** Copying leaves the original file where it is and places a duplicate in the backup folder. Moving transfers the file to the backup folder and removes it from its original location.

**Shift + F23 and Ctrl + F23** only work when a File Explorer window is open and in focus, since that is where you select files. The other two shortcuts work anywhere.


## Saving Clipboard Text

When you press `Alt + F23`, the utility takes whatever text you currently have copied to your clipboard and saves it as a plain text file in your backup folder. The file is named automatically using the date and time, for example:

```
clipboard_2026-04-01_14-32-05.txt
```

This is useful for quickly preserving a snippet, a web address, a note — anything you have copied without needing to open an editor and save manually.


## Confirmation Feedback

Every time an action is performed, the utility gives you two types of feedback so you always know it worked:

- **Sound** — a short two-tone chime on success, or a low error tone if something went wrong.
- **Visual** — a small coloured square flashes at the centre of your screen and fades out. Green with a ✓ means success; red with a ✗ means something went wrong.
