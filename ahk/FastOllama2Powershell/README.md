# Fast Ollama to Powershell

A fast, interactive AutoHotkey (v1.1) interface for Ollama that allows you to generate and execute PowerShell commands on the fly.

## Usage

1.  **Trigger**: Press `Pause + Space` (default) to open the centered GUI.
2.  **Phase 1 (Ollama)**: Type your natural language prompt (e.g., "list all files in the current directory over 100MB") and press **Enter**.
3.  **Edit Phase**: The Ollama result is displayed in the text box. You can now edit the generated command if needed.
4.  **Phase 2 (PowerShell)**: Press **Enter** again to execute the text in the box as a PowerShell command.
5.  **Finished**: The command result is displayed. The window is now locked. Press **Enter** or **Escape** to close the window.

> [!NOTE] 
> At any point the window can be closed using the **Escape** key. 

## Configuration

You can customize the script by editing the variables at the top of `FastOllama2Ps.ahk`:

- `TriggerKey`: The hotkey that opens the window (e.g., `^Space`).
- `OllamaModel`: The name of the Ollama model to use.
- `OllamaTimeout`: Max time (in seconds) to wait for a response.
- `BgColor`, `TextColor`, `EditBgColor`, etc.: Customize the look of the window.

## Customizing your Ollama Model

To get the best results (e.g., only receiving pure PowerShell commands without prose), it's recommended to create a custom model.

### Using `Example_ModelFile`

1.  Ensure you have a base model downloaded (e.g., `llama3`).
2.  Edit `Example_ModelFile`:
    - Change the `FROM` line to point to your base model (e.g., `FROM llama3`).
    - The `SYSTEM` prompt is already optimized for PowerShell command generation.
3.  Create the model in Ollama by running this in your terminal:
    ```powershell
    ollama create my_powershell_assistant -f Example_ModelFile
    ```
4.  Update your `FastOllama2Ps.ahk` configuration to use this new model name:
    ```autohotkey
    OllamaModel := "my_powershell_assistant"
    ```

## Requirements

- **AutoHotkey v1.1+**
- **Ollama** installed and running on your system.
- **PowerShell** (available by default on Windows).
