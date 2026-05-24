# PyLaunchKit

PyLaunchKit is a small launcher kit for Python projects.

It provides operating-system-specific startup files that prepare a local Python virtual environment, install dependencies only when needed, and run a Python module or script with a predictable command.

Start with the guide for your operating system:

- [Windows guide](Windows/README_WINDOWS.md)
- [macOS guide](MacOS/README_MACOS.md)

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

Each operating system has its own launcher folder and its own detailed README.

## Repository Layout

```text
PyLaunchKit/
|-- README.md
|-- Windows/
|   |-- README_WINDOWS.md
|   |-- run.bat
|   |-- run_terminal.vbs
|   `-- run_hidden.vbs
`-- MacOS/
    |-- README_MACOS.md
    |-- run.sh
    |-- run_terminal.command
    |-- run_gui.command
    `-- run_gui.applescript
```

The application files such as `src/main.py` and `req.txt` must be placed where the selected OS launcher expects them. See the OS-specific guide before copying the launcher into a real project.

## Windows

Use the Windows files when running the project on Windows:

```text
Windows/run.bat
Windows/run_terminal.vbs
Windows/run_hidden.vbs
```

Typical command:

```bat
Windows\run.bat
```

The Windows version uses:

- `run.bat` as the main launcher;
- `.vbs` files for double-click startup;
- a local `env` virtual environment;
- `req.txt` checksum tracking to avoid repeated dependency installation.

Read the full guide:

[Windows/README_WINDOWS.md](Windows/README_WINDOWS.md)

## macOS

Use the macOS files when running the project on macOS:

```text
MacOS/run.sh
MacOS/run_terminal.command
MacOS/run_gui.command
MacOS/run_gui.applescript
```

Typical command from the project root:

```bash
./MacOS/run.sh
```

The macOS version uses:

- `run.sh` as the main launcher;
- `.command` files for Finder startup;
- optional AppleScript for GUI-style startup;
- a local `.venv` virtual environment;
- `req.txt` checksum tracking to avoid repeated dependency installation.

Read the full guide:

[MacOS/README_MACOS.md](MacOS/README_MACOS.md)

## Running a Module

The default target is:

```text
src.main
```

To run another module, use the OS-specific launcher:

```bat
Windows\run.bat --module src.cli
```

```bash
./MacOS/run.sh --module src.cli
```

## Running a Python File

To run a file instead of a module:

```bat
Windows\run.bat --file tools\script.py
```

```bash
./MacOS/run.sh --file tools/script.py
```

## Passing Application Arguments

Use `--` to separate launcher arguments from application arguments.

Everything after `--` is passed to the Python application.

Windows:

```bat
Windows\run.bat --module src.cli -- --input "data\my file.txt"
```

macOS:

```bash
./MacOS/run.sh --module src.cli -- --input "data/my file.txt"
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

These options are documented in detail in the Windows and macOS guides.

## Important OS Differences

Windows uses `.bat` and `.vbs` files. Hidden double-click startup is possible through Windows Script Host.

macOS uses shell scripts, `.command` files, and optionally AppleScript or Automator. A `.command` file opened from Finder normally opens Terminal.

The virtual environment folder name is also different:

- Windows: `env`
- macOS: `.venv`

## Next Step

Open the guide for your operating system:

- [Windows guide](Windows/README_WINDOWS.md)
- [macOS guide](MacOS/README_MACOS.md)
