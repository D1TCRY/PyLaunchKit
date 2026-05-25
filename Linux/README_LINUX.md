# PyLaunchKit for Linux

PyLaunchKit is a small launcher kit for Python projects.

The Linux version starts a Python project through a local virtual environment, installs dependencies only when needed, and lets you choose whether to run a Python module or a Python file. By default, it runs:

```bash
python -m src.main
```

The launcher is designed to make everyday project startup predictable:

- it finds a usable Python 3 interpreter;
- it creates a local `.venv` if needed;
- it checks that `pip` is available inside the virtual environment;
- it installs dependencies from `req.txt` only when required;
- it runs the selected Python entrypoint;
- it forwards application arguments after `--`.

## Included Files

### `run.sh`

Main Linux launcher.

Use it from a terminal when you want to start the project, select a different module or file, recreate the virtual environment, or troubleshoot startup errors.

It is user-modifiable. Common safe changes include changing the default module or adapting messages for your project.

It should be executable when launched directly:

```bash
chmod +x run.sh
```

### `run_gui.desktop`

Desktop launcher for GUI-style startup.

Use it when your Python application opens its own window and does not need a visible terminal. It uses `Terminal=false`, so stdout and stderr may be hidden by the desktop environment.

It is user-modifiable. You may edit its `Name=`, `Comment=`, or `Exec=` fields if you want a different display name or default launcher arguments.

Some desktop environments require `.desktop` files to be executable or trusted before double-click launch works:

```bash
chmod +x run_gui.desktop
```

### `run_terminal.desktop`

Desktop launcher for terminal-style startup.

Use it when your Python application is a CLI tool, prints useful output, or when you want startup errors to be visible. This file starts `run_terminal.sh`, which opens a supported graphical terminal emulator and then runs `run.sh`.

It is user-modifiable. You may edit its `Name=`, `Comment=`, or `Exec=` fields if you want a different display name or default launcher arguments.

Some desktop environments require executable or trusted `.desktop` files:

```bash
chmod +x run_terminal.desktop
```

### `run_terminal.sh`

Terminal wrapper used by `run_terminal.desktop`.

It detects common graphical terminal emulators, opens one, runs `run.sh`, and keeps the terminal open when the application exits with an error.

Use it indirectly through `run_terminal.desktop`, or run it directly if you want the same terminal-launch behavior from a shell.

It should be executable when launched directly:

```bash
chmod +x run_terminal.sh
```

### `req.txt`

Optional requirements file.

If present, PyLaunchKit installs it into `.venv`. If it is missing, startup continues without dependency installation.

This file is user-modifiable. Add your Python package requirements here, one per line, using normal `pip` requirement syntax.

### `src/main.py`

Default Python entrypoint expected by the launcher.

By default, `run.sh` executes `src.main` as a module:

```bash
python -m src.main
```

This file is part of your application and is fully user-modifiable. You can also keep a different entrypoint and use `--module` or `--file`.

### `.venv/`

Local Python virtual environment created by PyLaunchKit.

It is generated automatically and should not normally be edited by hand. Delete or recreate it through:

```bash
./run.sh --recreate-venv
```

Do not commit `.venv/` to version control.

## Required Filesystem Layout

Typical project layout:

```text
PyLaunchKit/
├── run.sh
├── run_gui.desktop
├── run_terminal.desktop
├── run_terminal.sh
├── req.txt
├── .venv/
└── src/
    ├── __init__.py
    └── main.py
```

Required files:

- `run.sh`
- a Python entrypoint, normally `src/main.py`

Optional files:

- `run_gui.desktop`
- `run_terminal.desktop`
- `run_terminal.sh`
- `req.txt`
- `.venv/`

`.venv/` is created automatically. `req.txt` is optional. The `.desktop` files are only needed for double-click startup from a graphical desktop environment.

If you keep the Linux launcher files inside a `Linux/` folder, `run.sh` resolves the project directory as the parent directory of that folder. If you copy the Linux files into the root of your own project, the project directory is the directory containing `run.sh`.

## First Launch

On the first launch, run:

```bash
./run.sh
```

PyLaunchKit will:

1. Resolve the project directory.
2. Look for Python 3 as `python3` or `python`.
3. Create `.venv` if it does not exist.
4. Use `.venv/bin/python` for all Python operations after the virtual environment is created.
5. Check that `pip` works inside `.venv`.
6. Install dependencies from `req.txt` if `req.txt` exists.
7. Save a checksum of `req.txt` after a successful dependency installation.
8. Start the default application entrypoint:

```bash
python -m src.main
```

## Basic Terminal Usage

Start the default module:

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

Run another Python file:

```bash
./run.sh --file tools/script.py
```

## Passing Arguments to the Python Application

Use `--` to separate launcher arguments from application arguments.

Everything after `--` is passed to the Python application, not to PyLaunchKit.

Examples:

```bash
./run.sh -- --debug --name Mario
```

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

```bash
./run.sh --file tools/script.py -- --verbose
```

In this command:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

PyLaunchKit handles:

```text
--module src.cli
```

The Python application receives:

```text
--input "data/my file.txt"
```

Paths and arguments containing spaces must be quoted by the shell, as shown above.

## Maintenance Operations

Force dependency installation from `req.txt`:

```bash
./run.sh --force-setup
```

Use this when you want to reinstall requirements even though `req.txt` has not changed. Do not use it for normal startup, because it intentionally bypasses the checksum optimization.

Upgrade packaging tools inside `.venv`:

```bash
./run.sh --update-tools
```

This upgrades `pip`, `setuptools`, and `wheel`. Use it when dependency installation fails because packaging tools are outdated. Do not use it on every launch unless you specifically want that update step.

Delete and recreate `.venv`:

```bash
./run.sh --recreate-venv
```

Use this when the virtual environment is broken, when Python has changed, or when you want a clean environment. This removes the existing `.venv` and creates a new one in a controlled way.

You can combine maintenance options with normal launch options:

```bash
./run.sh --recreate-venv --module src.cli
```

## `req.txt` Handling

`req.txt` is optional.

If `req.txt` exists, PyLaunchKit installs it into the local virtual environment:

```bash
.venv/
```

PyLaunchKit calculates a SHA-256 checksum of `req.txt` and stores it inside the virtual environment after a successful installation. On the next launch:

- if `req.txt` has not changed, dependency installation is skipped;
- if `req.txt` has changed, dependencies are installed again;
- if installation fails, the saved checksum is not updated.

This avoids the common problem where requirements are reinstalled on every startup.

If `req.txt` is missing, PyLaunchKit prints a message and continues without installing dependencies.

## Double-Click Usage on Linux

Linux desktop startup depends on the desktop environment and file manager.

### GUI Launcher

Use:

```text
run_gui.desktop
```

This launcher uses `Terminal=false`. It is best for graphical Python applications that open their own window.

Because no terminal is shown, startup errors may not be visible. If the GUI launcher appears to do nothing, diagnose the problem by running:

```bash
./run.sh
```

or by using:

```text
run_terminal.desktop
```

### Terminal Launcher

Use:

```text
run_terminal.desktop
```

This launcher starts:

```text
run_terminal.sh
```

The wrapper looks for a supported terminal emulator, opens it, and runs:

```bash
./run.sh
```

This is better for CLI applications and for troubleshooting.

### Desktop Environment Notes

Different desktop environments handle `.desktop` files differently.

Some file managers require one or more of these steps:

- make the `.desktop` file executable;
- choose "Allow Launching";
- choose "Trust and Launch";
- move the launcher to the desktop or an applications folder;
- confirm that the file is trusted.

`Terminal=false` is appropriate for GUI applications. A terminal launcher or wrapper is appropriate for CLI applications.

For reliable diagnostics, run `./run.sh` from a terminal.

## Permissions

Recommended permission setup:

```bash
chmod +x run.sh
chmod +x run_terminal.sh
chmod +x run_gui.desktop
chmod +x run_terminal.desktop
```

Not every desktop environment requires executable permissions for `.desktop` files, but setting them often helps.

Some file managers also require a separate trust action even after `chmod +x`.

## Requirements

PyLaunchKit for Linux expects:

- Linux;
- Bash;
- Python 3 available as `python3`, or as `python` if it is Python 3;
- the Python `venv` module;
- Internet access only when dependencies need to be installed;
- `sha256sum`, normally provided by GNU coreutils;
- `openssl` as a fallback for checksum calculation;
- a graphical terminal emulator if you use `run_terminal.desktop`.

On Debian or Ubuntu, install the usual Python support packages with:

```bash
sudo apt install python3 python3-venv python3-pip
```

For `run_terminal.desktop`, at least one supported graphical terminal emulator should be installed. The wrapper checks common terminals such as GNOME Terminal, Konsole, Xfce Terminal, MATE Terminal, Kitty, Alacritty, and Xterm.

## Customization

### Change the Default Application

The default target is:

```text
src.main
```

The simplest customization is to edit your application code in:

```text
src/main.py
```

### Run a Different Module

Use:

```bash
./run.sh --module src.cli
```

This executes:

```bash
python -m src.cli
```

### Run a Python File

Use:

```bash
./run.sh --file tools/script.py
```

This executes the selected file with `.venv/bin/python`.

### Change the Default Target in `run.sh`

To permanently change the default module, edit this value in `run.sh`:

```bash
DEFAULT_MODULE="src.main"
```

For example:

```bash
DEFAULT_MODULE="src.cli"
```

### Add Default Arguments to Desktop Launchers

If you want a `.desktop` launcher to always pass specific arguments, edit its `Exec=` line.

For example, a launcher could run a different module:

```text
--module src.cli
```

or pass application arguments after `--`:

```text
-- --debug
```

Be careful when editing `Exec=` lines. Desktop entry quoting rules are stricter than normal shell usage, and behavior can vary between desktop environments.

## Troubleshooting

### `Permission denied`

Make the launcher executable:

```bash
chmod +x run.sh
```

For desktop launchers:

```bash
chmod +x run_gui.desktop
chmod +x run_terminal.desktop
chmod +x run_terminal.sh
```

Your file manager may also require "Allow Launching" or "Trust and Launch".

### `Python was not found`

Install Python 3 and make sure it is available as `python3`:

```bash
sudo apt install python3
```

Then try:

```bash
python3 --version
```

### `venv` or `ensurepip` is not available

On Debian or Ubuntu, install:

```bash
sudo apt install python3-venv python3-pip
```

Then recreate the virtual environment:

```bash
./run.sh --recreate-venv
```

### `pip` installation failed

Check the log file:

```text
run.log
```

Then try:

```bash
./run.sh --update-tools
```

If the environment is broken, try:

```bash
./run.sh --recreate-venv
```

### `req.txt` install fails

Check that every requirement in `req.txt` is valid for your Python version and Linux distribution.

Try installing again with:

```bash
./run.sh --force-setup
```

If the failure is caused by build tools or native libraries, install the required system packages for those Python dependencies.

### Desktop launcher does nothing

Run from a terminal:

```bash
./run.sh
```

This usually shows the real error.

Also check that:

- the `.desktop` file is executable or trusted;
- `run.sh` is executable;
- the `.desktop` file has not been moved away from the other launcher files;
- your desktop environment supports the way the `Exec=` line locates the launcher.

### Terminal does not open

`run_terminal.desktop` uses `run_terminal.sh`, which checks for common graphical terminal emulators.

Install one of the supported terminals, or run directly:

```bash
./run.sh
```

If no graphical terminal is available, `run_terminal.sh` exits with a clear error.

### Module not found

The default command is:

```bash
python -m src.main
```

Make sure the project contains:

```text
src/main.py
```

For package-style imports, also use:

```text
src/__init__.py
```

You can select another module:

```bash
./run.sh --module src.cli
```

### File not found

When using `--file`, paths are resolved relative to the project directory unless you provide an absolute path.

Example:

```bash
./run.sh --file tools/script.py
```

Make sure the file exists:

```text
tools/script.py
```

### File path with spaces

Quote paths that contain spaces:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

The launcher preserves arguments after `--`, but your shell still needs quotes around values containing spaces.

### GUI app starts from terminal but not from `.desktop`

This usually means the desktop environment is hiding the error or blocking the launcher.

Try:

```bash
./run.sh
```

Then try:

```text
run_terminal.desktop
```

Also confirm that the `.desktop` file is trusted and that your GUI application does not depend on environment variables that are only set in your interactive shell.

## Technical Notes

### Module Execution vs File Execution

Module execution:

```bash
python -m src.main
```

File execution:

```bash
python src/main.py
```

Module execution is usually better for structured projects because Python treats the project root as an import base. This makes package imports more predictable.

File execution is useful for standalone scripts, maintenance tools, and one-off utilities.

### Why `python -m src.main` Is the Default

`python -m src.main` is a good default for projects that use a package-like structure:

```text
src/
├── __init__.py
└── main.py
```

It encourages imports that work consistently when the project grows beyond a single script.

### Why a Local Virtual Environment Is Used

PyLaunchKit creates a project-local `.venv` so project dependencies do not pollute the system Python installation and different projects can use different dependency versions.

After `.venv` is created, PyLaunchKit uses:

```text
.venv/bin/python
```

for setup and for application startup.

### Why `req.txt` Uses a Checksum

Installing dependencies on every launch is slow and can fail unnecessarily when offline.

PyLaunchKit calculates a checksum of `req.txt`. If the checksum is unchanged, dependency installation is skipped. If the checksum changes, dependencies are installed again.

The checksum is saved only after a successful installation.

### Launcher Arguments vs Application Arguments

Launcher arguments control PyLaunchKit:

```bash
./run.sh --module src.cli
```

Application arguments are placed after `--`:

```bash
./run.sh --module src.cli -- --input "data/my file.txt"
```

In that example, PyLaunchKit consumes `--module src.cli`, and the Python app receives `--input "data/my file.txt"`.

### GUI `.desktop` vs Terminal `.desktop`

`run_gui.desktop` is for applications that do not need a visible terminal. It uses `Terminal=false`.

`run_terminal.desktop` is for CLI applications and diagnostics. It uses `run_terminal.sh` to open a terminal emulator and then run `run.sh`.

Linux desktop environments do not behave identically. Some require explicit trust or executable permissions for `.desktop` launchers.

## Differences from the Windows Version

The Windows version uses:

- `run.bat`;
- `.vbs` files for hidden or terminal-style startup;
- Windows virtual environment paths such as `Scripts/python.exe`.

The Linux version uses:

- `run.sh`;
- `.desktop` launchers;
- `run_terminal.sh` as a terminal wrapper;
- Linux virtual environment paths such as `.venv/bin/python`.

`.vbs` files do not exist on Linux.

On Linux, hidden-style startup is normally achieved with:

```text
Terminal=false
```

in a `.desktop` file.

The behavior of `.desktop` files depends on the desktop environment, the file manager, trust settings, and executable permissions.
