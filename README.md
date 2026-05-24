# PyLaunchKit

PyLaunchKit is a small Windows launcher kit for Python projects. Its goal is to make project startup repeatable and convenient by using a local virtual environment and by allowing the application to be started either from the terminal or through `.vbs` launcher files.

By default, PyLaunchKit runs:

```bat
python -m src.main
```

Therefore, if no options are provided, `run.bat` looks for and runs the Python module `src.main`.

---

## Included files

### `run.bat`

This is the main project launcher.

Main responsibilities:

- automatically switches to the folder where `run.bat` is located;
- looks for a system Python interpreter using, in order, `py -3`, `python`, and `python3`;
- creates or reuses the local virtual environment `env`;
- checks that `pip` is available inside the virtual environment;
- installs dependencies from `req.txt` only when the content of `req.txt` changes;
- stores the SHA-256 hash of `req.txt` in `env\.launcher\req.hash`;
- allows running either a Python module or an explicit Python file;
- forwards application arguments written after `--` to the Python application;
- can show additional diagnostics with `--debug`;
- can keep the terminal open on errors with `--pause-on-error`.

Default execution:

```bat
run.bat
```

Equivalent to:

```bat
python -m src.main
```

Run a different module:

```bat
run.bat --module tools.worker
```

Run a Python file:

```bat
run.bat --file main.py
```

Or:

```bat
run.bat --file tools\script.py
```

Use explicit mode and target:

```bat
run.bat --mode module --target src.main
run.bat --mode file --target tools\script.py
```

Pass arguments to the Python application:

```bat
run.bat --module src.main -- --name Mario --verbose
```

In this case:

- `--module src.main` is read by the launcher;
- everything after `--` is passed to the Python application.

Maintenance operations:

```bat
run.bat --force-setup
run.bat --update-tools
run.bat --recreate-venv
```

Meaning:

- `--force-setup`: reinstalls dependencies from `req.txt` even if the hash has not changed;
- `--update-tools`: upgrades `pip`, `setuptools`, and `wheel`;
- `--recreate-venv`: deletes and fully recreates the local virtual environment `env`.

Diagnostics:

```bat
run.bat --debug
```

Shows useful information such as the project folder, virtual environment, execution mode, target, and `req.txt` hash.

---

### `run_hidden.vbs`

This Visual Basic Script launcher starts `run.bat` without showing a terminal window.

It is useful for graphical applications, for example applications created with:

- `tkinter`;
- `customtkinter`;
- `PySide`;
- `PyQt`;
- `wxPython`.

The file:

- detects its own folder;
- builds the path to `run.bat` in the same folder;
- sets the current directory to the project folder;
- starts `run.bat` with a hidden window.

Current behavior:

```vbscript
objShell.Run Chr(34) & strBatch & Chr(34), 0, False
```

Where:

- `0` means hidden window;
- `False` means the `.vbs` script does not wait for the program to finish.

Typical use:

```text
Double-click run_hidden.vbs
```

---

### `run_terminal.vbs`

This Visual Basic Script launcher starts `run.bat` with a visible terminal.

It is useful for text-based applications or when you want to see output, errors, and logs while the program runs.

The file:

- detects its own folder;
- builds the path to `run.bat` in the same folder;
- sets the current directory to the project folder;
- opens `cmd.exe`;
- runs `run.bat`;
- closes the terminal when execution finishes.

Current behavior:

```vbscript
objShell.Run "cmd.exe /c " & Chr(34) & strBatch & Chr(34), 1, True
```

Where:

- `cmd.exe /c` runs the command and closes the terminal at the end;
- `1` shows the window in normal mode;
- `True` makes the `.vbs` script wait until the program finishes.

Typical use:

```text
Double-click run_terminal.vbs
```

---

### `README.md`

This is the project documentation file.

This README explains:

- the purpose of the project;
- the role of each file;
- the required filesystem structure;
- how to use `run.bat`;
- how to use the `.vbs` launchers;
- how to pass arguments from `.vbs` files to `run.bat`.

---

## Required filesystem structure

Recommended minimal structure:

```text
PyLaunchKit/
├─ run.bat
├─ run_hidden.vbs
├─ run_terminal.vbs
├─ README.md
├─ req.txt
├─ src/
│  └─ main.py
└─ env/
   └─ ...
```

Important notes:

- `run.bat`, `run_hidden.vbs`, and `run_terminal.vbs` must be in the same folder;
- `req.txt`, if present, must be in the same folder as `run.bat`;
- the default behavior requires `src\main.py`;
- the virtual environment `env` is created automatically by `run.bat`;
- the `env` folder should not be committed to Git;
- the `env\.launcher` folder is used internally by PyLaunchKit to store launcher state.

Minimal structure for the default behavior:

```text
PyLaunchKit/
├─ run.bat
├─ req.txt
└─ src/
   └─ main.py
```

Example `src/main.py`:

```python
print("Hello from PyLaunchKit")
```

Example `req.txt`:

```text
customtkinter
requests
```

If the project has no external dependencies, `req.txt` can be omitted. In that case, `run.bat` skips dependency installation.

---

## Technical behavior of `run.bat`

### 1. Project directory

At startup, `run.bat` gets its own folder with:

```bat
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
```

This ensures that execution always starts from the project directory, even when the file is opened by double-clicking or launched through a `.vbs` file.

### 2. Virtual environment

The virtual environment is located at:

```text
env/
```

The Python interpreter used by the project is:

```text
env\Scripts\python.exe
```

If it does not exist, `run.bat` creates it with:

```bat
python -m venv env
```

### 3. Dependencies

If `req.txt` exists, the launcher computes a SHA-256 hash of the file.

The hash is stored in:

```text
env\.launcher\req.hash
```

On the next run:

- if the hash is the same, dependencies are not reinstalled;
- if the hash is different, `pip install -r req.txt` is executed;
- if `--force-setup` is used, dependencies are reinstalled anyway.

This prevents `pip install` from running on every startup.

### 4. Python entrypoint

The launcher supports two modes:

```text
module
file
```

Module mode:

```bat
run.bat --module src.main
```

Runs:

```bat
python -m src.main
```

File mode:

```bat
run.bat --file tools\script.py
```

Runs:

```bat
python tools\script.py
```

The default is:

```bat
run.bat --module src.main
```

---

## Passing arguments to the Python application from `run.bat`

Arguments meant for the Python application must be written after `--`.

Example:

```bat
run.bat --module src.main -- --user Mario --debug-app
```

In Python, they can be read normally from `sys.argv`:

```python
import sys

print(sys.argv)
```

Conceptual output:

```text
['...', '--user', 'Mario', '--debug-app']
```

---

## Technical explanation: how `.vbs` files can pass command-line arguments to `run.bat`

The current `.vbs` files start `run.bat`, but they do not automatically forward the arguments received by the `.vbs` script.

To enable this behavior, the `.vbs` launcher must:

1. read the arguments received through `WScript.Arguments`;
2. safely quote each argument;
3. append those arguments to the command that starts `run.bat`.

### Updated `run_hidden.vbs` with argument forwarding

```vbscript
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strBatch = strPath & "\run.bat"

objShell.CurrentDirectory = strPath

strArgs = ""
For Each arg In WScript.Arguments
    strArgs = strArgs & " " & Chr(34) & Replace(arg, Chr(34), Chr(34) & Chr(34)) & Chr(34)
Next

' 0 = hidden window
' False = do not wait for the program to finish
objShell.Run Chr(34) & strBatch & Chr(34) & strArgs, 0, False

Set objShell = Nothing
Set objFSO = Nothing
```

Usage example:

```bat
wscript run_hidden.vbs --module src.main -- --name Mario
```

The effective command becomes, conceptually:

```bat
run.bat --module src.main -- --name Mario
```

### Updated `run_terminal.vbs` with argument forwarding

```vbscript
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strBatch = strPath & "\run.bat"

objShell.CurrentDirectory = strPath

strArgs = ""
For Each arg In WScript.Arguments
    strArgs = strArgs & " " & Chr(34) & Replace(arg, Chr(34), Chr(34) & Chr(34)) & Chr(34)
Next

' cmd.exe /c runs the command and closes the terminal at the end
objShell.Run "cmd.exe /c " & Chr(34) & Chr(34) & strBatch & Chr(34) & strArgs & Chr(34), 1, True

Set objShell = Nothing
Set objFSO = Nothing
```

Usage example:

```bat
wscript run_terminal.vbs --file tools\script.py -- --input data.txt
```

The effective command becomes, conceptually:

```bat
run.bat --file tools\script.py -- --input data.txt
```

### Why `WScript.Arguments` is required

When a `.vbs` script is started with command-line arguments, Windows exposes them through:

```vbscript
WScript.Arguments
```

Without iterating over `WScript.Arguments`, the `.vbs` script has no way to forward those arguments to `run.bat`.

### Why arguments must be quoted

Arguments may contain spaces:

```text
"Mario Rossi"
"C:\Users\Mario Rossi\Desktop\file.txt"
```

To prevent them from being split into multiple parts, each argument is wrapped in double quotes:

```vbscript
Chr(34) & arg & Chr(34)
```

Additionally, any double quotes inside the argument are doubled:

```vbscript
Replace(arg, Chr(34), Chr(34) & Chr(34))
```

This makes argument forwarding more robust.

---

## Complete practical examples

### GUI application without terminal

```text
Double-click run_hidden.vbs
```

By default, this requires:

```text
src\main.py
```

### Text-based application with visible terminal

```text
Double-click run_terminal.vbs
```

The terminal is shown during execution and closes when the program exits.

### Manual startup from terminal

```bat
run.bat
```

### Manual startup with application arguments

```bat
run.bat --module src.main -- --config config.json --verbose
```

### Full virtual environment recreation

```bat
run.bat --recreate-venv
```
