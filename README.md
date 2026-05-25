# PyLaunchKit

PyLaunchKit is a small launcher kit for Python projects.

It provides operating-system-specific startup files that prepare a local Python virtual environment, install dependencies only when needed, and run a Python module or script with a predictable command.

Start with the guide for your operating system:

- [Windows guide](Windows/README_WINDOWS.md)
- [macOS guide](MacOS/README_MACOS.md)
- [Linux guide](Linux/README_LINUX.md)

## What PyLaunchKit Does

PyLaunchKit is meant to make Python project startup repeatable.

The launchers handle the common setup work:

- find a usable Python 3 interpreter;
- create or reuse a local virtual environment;
- verify that `pip` works inside that environment;
- install dependencies from `req.txt` only when required;
- run the default Python entrypoint;
- allow a different module or file to be selected;
- pass application arguments after `--`.

By default, PyLaunchKit runs:

```text
python -m src.main
```

Each operating system has its own source folder in this repository and its own detailed README.

## Repository Source Layout

```text
PyLaunchKit/
|-- README.md
|-- Windows/
|   |-- README_WINDOWS.md
|   |-- run.bat
|   |-- run_hidden.vbs
|   `-- run_terminal.vbs
|-- MacOS/
|   |-- README_MACOS.md
|   |-- run.sh
|   |-- run_gui.applescript
|   |-- run_gui.command
|   `-- run_terminal.command
`-- Linux/
    |-- README_LINUX.md
    |-- run.sh
    |-- run_gui.desktop
    |-- run_terminal.desktop
    `-- run_terminal.sh
```

This is the layout of the PyLaunchKit repository, not the recommended layout for your application.

For a real project, copy the launcher files for your operating system into your own project directory. The project files such as `req.txt`, `src/main.py`, and the local virtual environment should live with those launchers as shown below.

## Recommended Project Layouts

Windows:

```text
ProjectDirectory/
|-- run.bat
|-- run_hidden.vbs
|-- run_terminal.vbs
|-- req.txt
|-- src/
|   |-- __init__.py
|   `-- main.py
`-- env/
```

macOS:

```text
ProjectDirectory/
|-- run.sh
|-- run_gui.applescript
|-- run_gui.command
|-- run_terminal.command
|-- req.txt
|-- src/
|   |-- __init__.py
|   `-- main.py
`-- .venv/
```

Linux:

```text
ProjectDirectory/
|-- run.sh
|-- run_gui.desktop
|-- run_terminal.desktop
|-- run_terminal.sh
|-- req.txt
|-- src/
|   |-- __init__.py
|   `-- main.py
`-- .venv/
```

The virtual environment folder is created automatically. `req.txt` is optional, but when it exists it should stay in `ProjectDirectory/`.

## Windows

For Windows projects, copy these files from `Windows/` into `ProjectDirectory/`:

```text
run.bat
run_hidden.vbs
run_terminal.vbs
```

Typical command:

```bat
run.bat
```

The Windows version uses:

- `run.bat` as the main launcher;
- `.vbs` files for double-click startup;
- a local `env` virtual environment;
- `req.txt` checksum tracking to avoid repeated dependency installation.

Read the full guide:

[Windows/README_WINDOWS.md](Windows/README_WINDOWS.md)

## macOS

For macOS projects, copy these files from `MacOS/` into `ProjectDirectory/`:

```text
run.sh
run_gui.applescript
run_gui.command
run_terminal.command
```

Typical command from `ProjectDirectory/`:

```bash
./run.sh
```

The macOS version uses:

- `run.sh` as the main launcher;
- `.command` files for Finder startup;
- optional AppleScript for GUI-style startup;
- a local `.venv` virtual environment;
- `req.txt` checksum tracking to avoid repeated dependency installation.

Read the full guide:

[MacOS/README_MACOS.md](MacOS/README_MACOS.md)

## Linux

For Linux projects, copy these files from `Linux/` into `ProjectDirectory/`:

```text
run.sh
run_gui.desktop
run_terminal.desktop
run_terminal.sh
```

Typical command from `ProjectDirectory/`:

```bash
./run.sh
```

The Linux version uses:

- `run.sh` as the main launcher;
- `.desktop` files for graphical desktop startup;
- `run_terminal.sh` as a wrapper for terminal-based desktop startup;
- a local `.venv` virtual environment;
- `req.txt` checksum tracking to avoid repeated dependency installation.

Read the full guide:

[Linux/README_LINUX.md](Linux/README_LINUX.md)

## Running a Module

The default target is:

```text
src.main
```

To run another module, use the OS-specific launcher:

```bat
run.bat --module src.cli
```

```bash
./run.sh --module src.cli
```

```bash
./run.sh --module src.cli
```

## Running a Python File

To run a file instead of a module:

```bat
run.bat --file tools\script.py
```

```bash
./run.sh --file tools/script.py
```

```bash
./run.sh --file tools/script.py
```

## Passing Application Arguments

Use `--` to separate launcher arguments from application arguments.

Everything after `--` is passed to the Python application.

Windows:

```bat
run.bat --module src.cli -- --input "data\my file.txt"
```

macOS:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

Linux:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

## Dependency Handling

`req.txt` is optional.

If it exists, PyLaunchKit installs it into the local virtual environment. A checksum is saved after successful installation, so the dependencies are not reinstalled on every launch.

When `req.txt` changes, the checksum changes and PyLaunchKit installs the updated dependencies on the next run.

## Maintenance Commands

Force dependency installation:

```text
--force-setup
```

Upgrade `pip`, `setuptools`, and `wheel`:

```text
--update-tools
```

Recreate the local virtual environment:

```text
--recreate-venv
```

These options are documented in detail in the Windows, macOS, and Linux guides.

## Important OS Differences

Windows uses `.bat` and `.vbs` files. Hidden double-click startup is possible through Windows Script Host.

macOS uses shell scripts, `.command` files, and optionally AppleScript or Automator. A `.command` file opened from Finder normally opens Terminal.

Linux uses shell scripts and `.desktop` files. Hidden-style startup is normally handled with `Terminal=false`, while terminal startup depends on the desktop environment and available terminal emulator.

The virtual environment folder name is also different:

- Windows: `env`
- macOS: `.venv`
- Linux: `.venv`

## Next Step

Open the guide for your operating system:

- [Windows guide](Windows/README_WINDOWS.md)
- [macOS guide](MacOS/README_MACOS.md)
- [Linux guide](Linux/README_LINUX.md)
