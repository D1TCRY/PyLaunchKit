# PyLaunchKit for macOS

For the cross-platform overview, start with the [root README](../README.md).

PyLaunchKit is a small launcher kit for Python projects.

The macOS version starts a Python project with a local virtual environment, optional dependency installation from `req.txt`, and flexible execution modes. By default, it runs:

```bash
python -m src.main
```

The launcher is designed to work from Terminal, from another working directory, and through double-clickable macOS `.command` wrappers.

## Included Files

### `run.sh`

`run.sh` is the main macOS launcher.

It:

- locates the project directory automatically;
- creates a local `.venv` virtual environment if it does not exist;
- uses `.venv/bin/python` to run the application;
- checks that `pip` is available inside the virtual environment;
- installs dependencies from `req.txt` only when needed;
- runs a Python module or a Python file;
- forwards application arguments written after `--`.

Use it when you want to start the project from Terminal.

This file can be edited by the user, especially to change the default module, but most projects should not need to modify it. It must be executable:

```bash
chmod +x run.sh
```

### `run_terminal.command`

`run_terminal.command` is a double-click launcher for Finder.

Finder opens `.command` files in Terminal. This wrapper finds `run.sh` next to itself and forwards all received arguments to it.

Use it when:

- you want to start the project by double-clicking;
- you want to see Terminal output;
- you are running a command-line application;
- you want visible error messages during startup.

This file can be edited by the user, but normally it should stay unchanged. It must be executable:

```bash
chmod +x run_terminal.command
```

### `run_gui.command`

`run_gui.command` is a Finder-friendly launcher intended for graphical Python applications.

It delegates to `run_gui.applescript` when AppleScript is available. If AppleScript is not available, it falls back to running `run.sh` in a visible Terminal.

Use it when:

- the Python project is a GUI application;
- you want a more GUI-like launch flow;
- you accept the real macOS limitation that a `.command` opened from Finder normally opens Terminal briefly.

This file can be edited by the user, but normally it should stay unchanged. It must be executable:

```bash
chmod +x run_gui.command
```

### `run_gui.applescript`

`run_gui.applescript` starts `run.sh` through AppleScript using `do shell script`.

It is useful for GUI applications because it can launch the Python process without keeping a Terminal window attached to the process. Application output is written to:

```text
run_gui.log
```

Arguments are forwarded when the script is launched through `osascript` or through `run_gui.command`. A compiled AppleScript app opened by double-click normally does not receive command-line arguments.

This file can be edited by the user. For a cleaner double-click GUI launcher, it can be compiled into a macOS app:

```bash
osacompile -o run_gui.app run_gui.applescript
```

### `req.txt`

`req.txt` is the optional dependency list for the Python project.

If it exists, PyLaunchKit installs it into `.venv` with:

```bash
python -m pip install -r req.txt
```

The file is user-editable. Add one dependency per line, using normal `pip` requirements syntax.

### `src/main.py`

`src/main.py` is the default Python entrypoint expected by PyLaunchKit.

By default, `run.sh` runs:

```bash
python -m src.main
```

This file is fully user-editable. It should contain the application startup code.

### `.venv/`

`.venv/` is the local Python virtual environment created by PyLaunchKit.

It is generated automatically and should not be edited manually. It should normally not be committed to version control.

PyLaunchKit stores its internal dependency state inside:

```text
.venv/.launcher/
```

## Required Filesystem Structure

The macOS launcher files belong in the `MacOS` folder. The project files live in the project root:

```text
PyLaunchKit/
|-- README.md
|-- MacOS/
|   |-- README_MACOS.md
|   |-- run.sh
|   |-- run_terminal.command
|   |-- run_gui.command
|   `-- run_gui.applescript
|-- req.txt
|-- .venv/
`-- src/
    |-- __init__.py
    `-- main.py
```

Required files:

- `MacOS/run.sh`
- `src/main.py`, unless you always use `--module` or `--file` with another target

Optional files:

- `MacOS/run_terminal.command`
- `MacOS/run_gui.command`
- `MacOS/run_gui.applescript`
- `req.txt`
- `.venv/`, created automatically

If you are inside the `MacOS` folder, use:

```bash
./run.sh
```

If you are in the project root, use:

```bash
./MacOS/run.sh
```

## First Launch

On the first launch, PyLaunchKit performs these steps:

1. Finds the project directory.
2. Looks for Python 3 using `python3` first, then `python`.
3. Creates the local virtual environment `.venv` if it does not exist.
4. Uses `.venv/bin/python` for all project execution.
5. Checks that `pip` works inside `.venv`.
6. Installs dependencies from `req.txt` if the file exists.
7. Saves a checksum of `req.txt` after a successful dependency installation.
8. Starts the default module `src.main`.

The default launch is equivalent to:

```bash
python -m src.main
```

but it uses the Python interpreter inside `.venv`.

## Basic Terminal Usage

Run the default application:

```bash
./run.sh
```

Show help:

```bash
./run.sh --help
```

Run the default module explicitly:

```bash
./run.sh --module src.main
```

Run another module:

```bash
./run.sh --module src.cli
```

Run a Python file:

```bash
./run.sh --file src/main.py
```

Run a Python file in another folder:

```bash
./run.sh --file tools/script.py
```

## Passing Arguments to the Python Application

Launcher options are read before the separator:

```text
--
```

Everything after `--` is passed unchanged to the Python application.

Example using the default module:

```bash
./run.sh -- --debug --name Mario
```

Example using a custom module:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

Example using a Python file:

```bash
./run.sh --file tools/script.py -- --verbose
```

In these examples:

- options before `--` belong to PyLaunchKit;
- arguments after `--` belong to your Python application;
- quoted values with spaces are preserved.

## Maintenance Operations

Force dependency installation from `req.txt`:

```bash
./run.sh --force-setup
```

Use this when you want to reinstall requirements even if `req.txt` did not change. Do not use it for normal daily startup because it intentionally bypasses the checksum optimization.

Upgrade packaging tools:

```bash
./run.sh --update-tools
```

This upgrades `pip`, `setuptools`, and `wheel` inside `.venv`. Use it when package installation fails because the packaging tools are old. It is not run automatically on every startup.

Delete and recreate the virtual environment:

```bash
./run.sh --recreate-venv
```

Use this when `.venv` is broken, corrupted, created with the wrong Python version, or needs a full reset. Do not use it for normal daily startup because it removes and rebuilds the environment.

## `req.txt` Handling

`req.txt` is optional.

If `req.txt` does not exist, PyLaunchKit skips dependency installation and starts the application.

If `req.txt` exists, PyLaunchKit:

1. calculates a SHA-256 checksum of the file;
2. compares it with the checksum saved from the previous successful installation;
3. installs dependencies only when the checksum is new or different;
4. saves the new checksum only after installation succeeds.

This avoids the classic problem where dependencies are reinstalled on every launch.

If you modify `req.txt`, PyLaunchKit detects the new checksum and reinstalls dependencies on the next launch.

If `req.txt` does not change, dependencies are not reinstalled every time.

## Double-Click Usage on macOS

### Terminal Mode

Use:

```text
run_terminal.command
```

When opened from Finder, this normally opens Terminal and runs `run.sh`.

Before using it, make it executable:

```bash
chmod +x run.sh run_terminal.command run_gui.command
```

### GUI Mode

Use:

```text
run_gui.command
```

This wrapper tries to use `run_gui.applescript`. It is intended for graphical Python applications.

Important macOS reality:

- a `.command` file opened from Finder normally opens Terminal;
- it may only appear briefly, but it is still part of how Finder runs `.command` files;
- a truly GUI-style launcher may require AppleScript, Automator, or a wrapped macOS `.app`;
- a compiled AppleScript app opened by double-click normally does not receive command-line arguments.

To compile the AppleScript wrapper:

```bash
osacompile -o run_gui.app run_gui.applescript
```

The AppleScript launcher starts the process in the background and writes output to:

```text
run_gui.log
```

Because the Python process is backgrounded, the AppleScript launcher reports launch success, not the final exit code of the Python application.

## Permissions

From the `MacOS` folder, run:

```bash
chmod +x run.sh
chmod +x run_terminal.command
chmod +x run_gui.command
```

Or in one command:

```bash
chmod +x run.sh run_terminal.command run_gui.command
```

If you compile the AppleScript:

```bash
osacompile -o run_gui.app run_gui.applescript
```

Depending on macOS security settings, the first launch of a generated app may require approval in System Settings or a contextual Open action from Finder.

## Requirements

PyLaunchKit for macOS requires:

- macOS;
- Bash, available by default on macOS;
- Python 3 available as `python3` or `python`;
- `shasum`, normally available by default on macOS;
- Internet access only when dependencies need to be downloaded or upgraded.

No GNU coreutils dependency is required.

## Customization

The default target is:

```text
src.main
```

You can customize startup in several ways.

Edit `src/main.py` if your project should keep the default module path.

Run a different module without editing the launcher:

```bash
./run.sh --module src.cli
```

Run a Python file directly:

```bash
./run.sh --file tools/script.py
```

Advanced users can edit `run.sh` and change:

```bash
DEFAULT_MODULE="src.main"
```

Only change this if you want a different default for every launch.

## Troubleshooting

### Permission denied

The launcher is probably not executable.

Run this from the `MacOS` folder:

```bash
chmod +x run.sh run_terminal.command run_gui.command
```

### Python not found

Install Python 3 and make sure it is available as:

```bash
python3
```

Check with:

```bash
python3 --version
```

### pip installation failed

Try:

```bash
./run.sh --update-tools
```

If the virtual environment is broken, recreate it:

```bash
./run.sh --recreate-venv
```

### `req.txt` install fails

Open `run.log` in the project root and inspect the pip error.

Common causes include:

- misspelled package names;
- incompatible package versions;
- missing compiler tools;
- no Internet connection;
- private packages that require authentication.

After fixing `req.txt`, run:

```bash
./run.sh --force-setup
```

### Terminal window opens when double-clicking

This is normal for `.command` files on macOS.

Use `run_gui.command`, AppleScript, Automator, or a compiled wrapper app if you need a more GUI-like startup experience.

### App does not start from Finder

Check that:

- `run_terminal.command` or `run_gui.command` is executable;
- `run.sh` is executable;
- Python 3 is installed;
- the expected module or file exists;
- `run.log` or `run_gui.log` contains useful error output.

### Module not found

The default module is:

```text
src.main
```

For this to work, the project should contain:

```text
src/main.py
```

For package-style projects, it is also recommended to include:

```text
src/__init__.py
```

You can also select another module:

```bash
./run.sh --module src.cli
```

### File not found

When using `--file`, paths are resolved relative to the project root unless they are absolute.

Example:

```bash
./run.sh --file tools/script.py
```

### File path with spaces

Quote paths that contain spaces:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

The launcher preserves quoted application arguments after `--`.

## Technical Notes

### Module execution vs file execution

Module execution:

```bash
python -m src.main
```

File execution:

```bash
python src/main.py
```

Module execution is usually better for structured projects because Python treats the project root as an import root and runs the module by package name. This makes imports more predictable in package-based layouts.

File execution is useful for standalone scripts or tools that are not meant to be imported as modules.

### Why `python -m src.main` is the default

`python -m src.main` is a good default for structured Python projects because it encourages a package layout and avoids many path-related surprises that happen when running files directly.

### Why a local virtual environment is used

The local `.venv` keeps project dependencies separate from system Python and from other projects.

This makes startup more repeatable and reduces the chance that one project breaks another project's dependencies.

### Why a checksum is used for `req.txt`

Installing dependencies on every startup is slow and unnecessary.

PyLaunchKit calculates a checksum of `req.txt` and stores it after successful installation. On later launches, if the checksum is unchanged, dependency installation is skipped.

### Launcher arguments vs application arguments

Launcher arguments control PyLaunchKit itself:

```bash
./run.sh --module src.cli
```

Application arguments are placed after `--` and are passed to Python:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

In this command:

- `--module src.cli` is for PyLaunchKit;
- `--input "data/my file.txt"` is for the Python application.

## Differences from the Windows Version

The Windows version uses:

- `run.bat`;
- `.vbs` launchers such as `run_terminal.vbs` and `run_hidden.vbs`.

The macOS version uses:

- `run.sh`;
- `.command` wrappers;
- optionally AppleScript, Automator, or a generated macOS app wrapper.

`.vbs` files do not exist on macOS.

The Windows hidden-launch behavior is also different from macOS. On macOS, a `.command` file opened from Finder normally opens Terminal. For GUI-style launching without a persistent Terminal window, use AppleScript, Automator, or an app wrapper, while remembering that command-line argument forwarding is limited when launching a compiled app by double-click.
