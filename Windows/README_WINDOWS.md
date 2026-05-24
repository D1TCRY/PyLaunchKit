# PyLaunchKit for Windows

For the cross-platform overview, start with the [root README](../README.md).

PyLaunchKit is a small launcher kit for Python projects.

The Windows version starts a Python project with a local virtual environment, optional dependency installation from `req.txt`, and flexible execution modes. By default, it runs:

```bat
python -m src.main
```

The launcher is designed to work from Command Prompt, from another working directory, and through double-clickable Windows `.vbs` wrappers.

## Included Files

### `run.bat`

`run.bat` is the main Windows launcher.

It:

- switches to the folder where `run.bat` is located;
- looks for Python using `py -3`, then `python`, then `python3`;
- creates a local `env` virtual environment if it does not exist;
- uses `env\Scripts\python.exe` to run the application;
- checks that `pip` is available inside the virtual environment;
- installs dependencies from `req.txt` only when needed;
- runs a Python module or a Python file;
- forwards application arguments written after `--`;
- supports maintenance options for setup, packaging tools, and virtual environment recreation.

Use it when you want to start the project from Command Prompt or from another script.

This file can be edited by the user, especially to change the default module, but most projects should not need to modify it.

### `run_terminal.vbs`

`run_terminal.vbs` is a double-click launcher for Windows.

It starts `run.bat` through `cmd.exe` with a visible terminal window. It waits until `run.bat` finishes.

Use it when:

- you want to start the project by double-clicking;
- you want to see terminal output;
- you are running a command-line application;
- you want visible startup errors.

The current file launches the default command and does not forward custom command-line arguments. If you need `--module`, `--file`, or application arguments, run `run.bat` directly from Command Prompt.

This file can be edited by the user, but normally it should stay unchanged.

### `run_hidden.vbs`

`run_hidden.vbs` is a double-click launcher for graphical Windows applications.

It starts `run.bat` without showing a terminal window and does not wait for the application to finish.

Use it when:

- the Python project is a GUI application;
- you do not want a visible terminal window;
- the application does not rely on terminal input or terminal output.

The current file launches the default command and does not forward custom command-line arguments. If you need arguments, run `run.bat` directly or customize the `.vbs` file.

This file can be edited by the user, but normally it should stay unchanged.

### `req.txt`

`req.txt` is the optional dependency list for the Python project.

If it exists next to `run.bat`, PyLaunchKit installs it into `env` with:

```bat
python -m pip install -r req.txt
```

The file is user-editable. Add one dependency per line, using normal `pip` requirements syntax.

### `src\main.py`

`src\main.py` is the default Python entrypoint expected by PyLaunchKit.

By default, `run.bat` runs:

```bat
python -m src.main
```

This file is fully user-editable. It should contain the application startup code.

### `env\`

`env\` is the local Python virtual environment created by PyLaunchKit on Windows.

It is generated automatically and should not be edited manually. It should normally not be committed to version control.

PyLaunchKit stores its internal dependency state inside:

```text
env\.launcher\
```

## Required Filesystem Structure

The Windows launcher files belong in the `Windows` folder.

The current Windows launcher uses its own folder as the project folder. That means `req.txt`, `src\`, and `env\` are expected next to `run.bat` unless you edit `run.bat` for a different layout.

Recommended Windows structure:

```text
PyLaunchKit/
|-- README.md
|-- Windows/
|   |-- README_WINDOWS.md
|   |-- run.bat
|   |-- run_terminal.vbs
|   |-- run_hidden.vbs
|   |-- req.txt
|   |-- env/
|   `-- src/
|       |-- __init__.py
|       `-- main.py
`-- MacOS/
    |-- README_MACOS.md
    |-- run.sh
    |-- run_terminal.command
    |-- run_gui.command
    `-- run_gui.applescript
```

Required files:

- `Windows\run.bat`
- `Windows\src\main.py`, unless you always use `--module` or `--file` with another target

Optional files:

- `Windows\run_terminal.vbs`
- `Windows\run_hidden.vbs`
- `Windows\req.txt`
- `Windows\env\`, created automatically

If you are inside the `Windows` folder, use:

```bat
run.bat
```

If you are in the project root, use:

```bat
Windows\run.bat
```

## First Launch

On the first launch, PyLaunchKit performs these steps:

1. Enters the folder where `run.bat` is located.
2. Looks for Python 3 using `py -3`, then `python`, then `python3`.
3. Creates the local virtual environment `env` if it does not exist.
4. Uses `env\Scripts\python.exe` for project execution.
5. Checks that `pip` works inside `env`.
6. Installs dependencies from `req.txt` if the file exists.
7. Saves a checksum of `req.txt` after a successful dependency installation.
8. Starts the default module `src.main`.

The default launch is equivalent to:

```bat
python -m src.main
```

but it uses the Python interpreter inside `env`.

## Basic Command Prompt Usage

Run the default application:

```bat
run.bat
```

Show help:

```bat
run.bat --help
```

Run the default module explicitly:

```bat
run.bat --module src.main
```

Run another module:

```bat
run.bat --module src.cli
```

Run a Python file:

```bat
run.bat --file src\main.py
```

Run a Python file in another folder:

```bat
run.bat --file tools\script.py
```

Windows also supports explicit mode and target:

```bat
run.bat --mode module --target src.main
run.bat --mode file --target tools\script.py
```

## Passing Arguments to the Python Application

Launcher options are read before the separator:

```text
--
```

Everything after `--` is passed to the Python application.

Example using the default module:

```bat
run.bat -- --debug --name Mario
```

Example using a custom module:

```bat
run.bat --module src.cli -- --input "data\my file.txt"
```

Example using a Python file:

```bat
run.bat --file tools\script.py -- --verbose
```

In these examples:

- options before `--` belong to PyLaunchKit;
- arguments after `--` belong to your Python application;
- quoted values with spaces are preserved by `run.bat`.

## Maintenance Operations

Force dependency installation from `req.txt`:

```bat
run.bat --force-setup
```

Use this when you want to reinstall requirements even if `req.txt` did not change. Do not use it for normal daily startup because it intentionally bypasses the checksum optimization.

Upgrade packaging tools:

```bat
run.bat --update-tools
```

This upgrades `pip`, `setuptools`, and `wheel` inside `env`. Use it when package installation fails because the packaging tools are old. It is not run automatically on every startup.

Delete and recreate the virtual environment:

```bat
run.bat --recreate-venv
```

Use this when `env` is broken, corrupted, created with the wrong Python version, or needs a full reset. Do not use it for normal daily startup because it removes and rebuilds the environment.

Show diagnostic information:

```bat
run.bat --debug
```

This prints useful launcher state such as the script folder, virtual environment path, selected run mode, target, and application arguments.

## `req.txt` Handling

`req.txt` is optional.

If `req.txt` does not exist, PyLaunchKit skips dependency installation and starts the application.

If `req.txt` exists, PyLaunchKit:

1. calculates a SHA-256 checksum of the file;
2. compares it with the checksum saved from the previous successful installation;
3. installs dependencies only when the checksum is new or different;
4. saves the new checksum only after installation succeeds.

The checksum is stored in:

```text
env\.launcher\req.hash
```

This avoids the classic problem where dependencies are reinstalled on every launch.

If you modify `req.txt`, PyLaunchKit detects the new checksum and reinstalls dependencies on the next launch.

If `req.txt` does not change, dependencies are not reinstalled every time.

## Double-Click Usage on Windows

### Terminal Mode

Use:

```text
run_terminal.vbs
```

Double-clicking this file starts `run.bat` in a visible Command Prompt window.

It is useful for text-based programs and for debugging startup problems.

### Hidden GUI Mode

Use:

```text
run_hidden.vbs
```

Double-clicking this file starts `run.bat` without showing a terminal window.

It is useful for GUI applications built with frameworks such as:

- `tkinter`
- `customtkinter`
- `PySide`
- `PyQt`
- `wxPython`

Important Windows reality:

- hidden startup is possible through Windows Script Host;
- terminal output is not visible in hidden mode;
- the current `.vbs` files do not forward command-line arguments;
- use `run.bat` from Command Prompt when you need custom launcher or application arguments.

## Permissions

Windows does not require `chmod +x`.

The `.bat` and `.vbs` files run through Windows file associations.

If Windows blocks the scripts, check:

- Windows SmartScreen;
- antivirus policy;
- company device policy;
- whether Windows Script Host is disabled.

## Requirements

PyLaunchKit for Windows requires:

- Windows;
- Command Prompt;
- Python 3 available as `py -3`, `python`, or `python3`;
- PowerShell or `certutil` for SHA-256 checksum calculation;
- Windows Script Host for `.vbs` double-click launchers;
- Internet access only when dependencies need to be downloaded or upgraded.

No Unix shell is required.

## Customization

The default target is:

```text
src.main
```

You can customize startup in several ways.

Edit `src\main.py` if your project should keep the default module path.

Run a different module without editing the launcher:

```bat
run.bat --module src.cli
```

Run a Python file directly:

```bat
run.bat --file tools\script.py
```

Advanced users can edit `run.bat` and change:

```bat
set "RUN_MODE=module"
set "RUN_TARGET=src.main"
```

Only change these defaults if you want a different target for every launch.

## Troubleshooting

### `run.bat` is not recognized

You are probably not in the `Windows` folder and did not include the path.

From the project root, run:

```bat
Windows\run.bat
```

From inside the `Windows` folder, run:

```bat
run.bat
```

### Python not found

Install Python 3 and make sure one of these commands works:

```bat
py -3 --version
python --version
python3 --version
```

### pip installation failed

Try:

```bat
run.bat --update-tools
```

If the virtual environment is broken, recreate it:

```bat
run.bat --recreate-venv
```

### `req.txt` install fails

Open `run.log` next to `run.bat` and inspect the pip error.

Common causes include:

- misspelled package names;
- incompatible package versions;
- missing compiler tools;
- no Internet connection;
- private packages that require authentication.

After fixing `req.txt`, run:

```bat
run.bat --force-setup
```

### Terminal closes too quickly

Run `run.bat` manually from Command Prompt so the output remains visible.

You can also use:

```bat
run.bat --pause-on-error
```

### Hidden app does not seem to start

Use `run_terminal.vbs` or run `run.bat` from Command Prompt to see errors.

Also check:

- `run.log`;
- Python installation;
- missing dependencies;
- whether the expected module or file exists.

### Module not found

The default module is:

```text
src.main
```

For this to work, the Windows project folder should contain:

```text
src\main.py
```

For package-style projects, it is also recommended to include:

```text
src\__init__.py
```

You can also select another module:

```bat
run.bat --module src.cli
```

### File not found

When using `--file`, paths are resolved relative to the current working directory after `run.bat` enters its own folder.

Example:

```bat
run.bat --file tools\script.py
```

### File path with spaces

Quote paths that contain spaces:

```bat
run.bat --module src.cli -- --input "data\my file.txt"
```

The launcher preserves quoted application arguments after `--`.

## Technical Notes

### Module execution vs file execution

Module execution:

```bat
python -m src.main
```

File execution:

```bat
python src\main.py
```

Module execution is usually better for structured projects because Python treats the project folder as an import root and runs the module by package name. This makes imports more predictable in package-based layouts.

File execution is useful for standalone scripts or tools that are not meant to be imported as modules.

### Why `python -m src.main` is the default

`python -m src.main` is a good default for structured Python projects because it encourages a package layout and avoids many path-related surprises that happen when running files directly.

### Why a local virtual environment is used

The local `env` keeps project dependencies separate from system Python and from other projects.

This makes startup more repeatable and reduces the chance that one project breaks another project's dependencies.

### Why a checksum is used for `req.txt`

Installing dependencies on every startup is slow and unnecessary.

PyLaunchKit calculates a checksum of `req.txt` and stores it after successful installation. On later launches, if the checksum is unchanged, dependency installation is skipped.

### Launcher arguments vs application arguments

Launcher arguments control PyLaunchKit itself:

```bat
run.bat --module src.cli
```

Application arguments are placed after `--` and are passed to Python:

```bat
run.bat --module src.cli -- --input "data\my file.txt"
```

In this command:

- `--module src.cli` is for PyLaunchKit;
- `--input "data\my file.txt"` is for the Python application.

### `.bat` vs `.vbs`

Use `run.bat` when you need full control, command-line arguments, debugging, or maintenance options.

Use `run_terminal.vbs` when you want a visible double-click launcher.

Use `run_hidden.vbs` when you want a hidden double-click launcher for GUI applications.

## Differences from the macOS Version

The Windows version uses:

- `run.bat`;
- `.vbs` launchers such as `run_terminal.vbs` and `run_hidden.vbs`;
- `env\Scripts\python.exe`;
- PowerShell or `certutil` for hashing.

The macOS version uses:

- `run.sh`;
- `.command` wrappers;
- optionally AppleScript, Automator, or a generated macOS app wrapper;
- `.venv/bin/python`;
- `shasum` for hashing.

`.vbs` files do not exist on macOS.

The Windows hidden-launch behavior is also different from macOS. Windows can start a process hidden through Windows Script Host. On macOS, a `.command` file opened from Finder normally opens Terminal, so GUI-style launchers usually require AppleScript, Automator, or an app wrapper.
