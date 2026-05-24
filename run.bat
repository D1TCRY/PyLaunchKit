@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ==================================================
rem PyLaunchKit - Python project launcher
rem ==================================================
rem Default behavior:
rem   python -m src.main
rem
rem Main features:
rem   - creates/reuses a local virtual environment in .\env
rem   - installs dependencies from .\req.txt only when req.txt changes
rem   - supports explicit module or file execution
rem   - forwards application arguments after --
rem ==================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "VENV_DIR=%SCRIPT_DIR%env"
set "VENV_PY=%VENV_DIR%\Scripts\python.exe"
set "REQ_FILE=%SCRIPT_DIR%req.txt"
set "LOG_FILE=%SCRIPT_DIR%run.log"
set "STATE_DIR=%VENV_DIR%\.launcher"
set "REQ_HASH_FILE=%STATE_DIR%\req.hash"

rem ==================================================
rem Default launcher options
rem ==================================================
set "FORCE_SETUP=0"
set "UPDATE_TOOLS=0"
set "RECREATE_VENV=0"
set "SHOW_HELP=0"
set "DEBUG_MODE=0"
set "PAUSE_ON_ERROR=0"

rem ==================================================
rem Default application entrypoint
rem ==================================================
set "RUN_MODE=module"
set "RUN_TARGET=src.main"
set "APP_ARGS="

call :parse_args %*
if errorlevel 1 exit /b 1

if "%SHOW_HELP%"=="1" (
    call :show_help
    exit /b 0
)

call :validate_entrypoint_options
if errorlevel 1 exit /b 1

echo ==================================================
echo PyLaunchKit - Python project launcher
echo ==================================================
echo.

if "%RECREATE_VENV%"=="1" (
    echo Option enabled: recreate virtual environment.
    echo Removing virtual environment...
    rmdir /s /q "%VENV_DIR%" >nul 2>&1
    echo.
)

call :find_system_python
if errorlevel 1 goto :fatal_no_python

call :ensure_venv
if errorlevel 1 goto :fatal_venv

call :ensure_pip_light
if errorlevel 1 goto :fatal_pip

call :maybe_upgrade_tools
if errorlevel 1 goto :fatal_pip

call :maybe_install_requirements
if errorlevel 1 goto :fatal_requirements

call :validate_entrypoint_runtime
if errorlevel 1 goto :fatal_entrypoint

if "%DEBUG_MODE%"=="1" (
    echo Debug:
    echo   Script dir       : %SCRIPT_DIR%
    echo   Virtual env      : %VENV_DIR%
    echo   Python executable: %VENV_PY%
    echo   Run mode         : %RUN_MODE%
    echo   Run target       : %RUN_TARGET%
    echo   App arguments    : !APP_ARGS!
    echo.
)

echo Starting application...
echo.

call :run_application
set "APP_EXIT_CODE=%ERRORLEVEL%"

if not "%APP_EXIT_CODE%"=="0" (
    echo.
    echo The application exited with an error.
    echo Exit code: %APP_EXIT_CODE%
    echo.
    call :maybe_pause
    exit /b %APP_EXIT_CODE%
)

exit /b 0


rem ==================================================
rem Argument parsing
rem ==================================================
:parse_args
if "%~1"=="" exit /b 0

:parse_args_loop
if "%~1"=="" exit /b 0

if "%~1"=="--" (
    shift
    goto :collect_app_args
)

if /i "%~1"=="--force-setup" (
    set "FORCE_SETUP=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--update-tools" (
    set "UPDATE_TOOLS=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--recreate-venv" (
    set "RECREATE_VENV=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--debug" (
    set "DEBUG_MODE=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--pause-on-error" (
    set "PAUSE_ON_ERROR=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--help" (
    set "SHOW_HELP=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="-h" (
    set "SHOW_HELP=1"
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--mode" (
    if "%~2"=="" (
        echo Missing value for --mode.
        echo.
        call :show_help
        exit /b 1
    )
    set "RUN_MODE=%~2"
    shift
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--module" (
    if "%~2"=="" (
        echo Missing value for --module.
        echo.
        call :show_help
        exit /b 1
    )
    set "RUN_MODE=module"
    set "RUN_TARGET=%~2"
    shift
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--file" (
    if "%~2"=="" (
        echo Missing value for --file.
        echo.
        call :show_help
        exit /b 1
    )
    set "RUN_MODE=file"
    set "RUN_TARGET=%~2"
    shift
    shift
    goto :parse_args_loop
)

if /i "%~1"=="--target" (
    if "%~2"=="" (
        echo Missing value for --target.
        echo.
        call :show_help
        exit /b 1
    )
    set "RUN_TARGET=%~2"
    shift
    shift
    goto :parse_args_loop
)

echo Unknown launcher option: %~1
echo.
echo Application arguments must be placed after --
echo Example:
echo   run.bat --module src.main -- --name Mario --verbose
echo.
call :show_help
exit /b 1

:collect_app_args
if "%~1"=="" exit /b 0
set "APP_ARGS=!APP_ARGS! ^"%~1^""
shift
goto :collect_app_args


:show_help
echo Usage:
echo   run.bat [launcher options] [-- app arguments]
echo.
echo Default execution:
echo   run.bat
echo   ^> python -m src.main
echo.
echo Launcher options:
echo   --module MODULE       Execute a Python module with: python -m MODULE
echo   --file FILE           Execute a Python file with: python FILE
echo   --mode module^|file    Select execution mode. Use together with --target.
echo   --target TARGET       Target used by --mode.
echo   --force-setup         Reinstall dependencies from req.txt even if unchanged.
echo   --update-tools        Upgrade pip, setuptools and wheel.
echo   --recreate-venv       Delete and recreate the virtual environment.
echo   --debug               Show additional launcher diagnostics.
echo   --pause-on-error      Keep the terminal open when an error occurs.
echo   --help, -h            Show this help message.
echo.
echo Application arguments:
echo   Everything after -- is forwarded to the Python application.
echo.
echo Examples:
echo   run.bat
echo   run.bat --module src.main
echo   run.bat --module tools.worker
echo   run.bat --file main.py
echo   run.bat --file tools\script.py
echo   run.bat --mode module --target src.main
echo   run.bat --mode file --target tools\script.py
echo   run.bat --module src.main -- --name Mario --verbose
echo   run.bat --file tools\script.py -- --input "data file.txt"
echo   run.bat --force-setup
echo   run.bat --update-tools
echo   run.bat --recreate-venv
exit /b 0


rem ==================================================
rem Entrypoint validation
rem ==================================================
:validate_entrypoint_options
if /i "%RUN_MODE%"=="module" (
    set "RUN_MODE=module"
    if "%RUN_TARGET%"=="" (
        echo Module target cannot be empty.
        exit /b 1
    )
    exit /b 0
)

if /i "%RUN_MODE%"=="file" (
    set "RUN_MODE=file"
    if "%RUN_TARGET%"=="" (
        echo File target cannot be empty.
        exit /b 1
    )
    call :normalize_file_target
    if errorlevel 1 exit /b 1
    exit /b 0
)

echo Invalid --mode value: %RUN_MODE%
echo Allowed values: module, file
echo.
call :show_help
exit /b 1

:normalize_file_target
for %%F in ("%RUN_TARGET%") do set "RUN_TARGET=%%~fF"
exit /b 0

:validate_entrypoint_runtime
if "%RUN_MODE%"=="file" (
    if not exist "%RUN_TARGET%" (
        echo Python file not found:
        echo   %RUN_TARGET%
        exit /b 1
    )
    exit /b 0
)

if "%RUN_MODE%"=="module" (
    "%VENV_PY%" -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec(sys.argv[1]) else 1)" "%RUN_TARGET%" >nul 2>&1
    if errorlevel 1 (
        echo Python module not found or not importable:
        echo   %RUN_TARGET%
        echo.
        echo Default expected project file:
        echo   %SCRIPT_DIR%src\main.py
        exit /b 1
    )
    exit /b 0
)

exit /b 1


rem ==================================================
rem Python / venv / pip setup
rem ==================================================
:find_system_python
set "SYS_PY="

where py >nul 2>&1
if not errorlevel 1 (
    py -3 --version >nul 2>&1
    if not errorlevel 1 (
        set "SYS_PY=py -3"
        goto :python_found
    )
)

where python >nul 2>&1
if not errorlevel 1 (
    python --version >nul 2>&1
    if not errorlevel 1 (
        set "SYS_PY=python"
        goto :python_found
    )
)

where python3 >nul 2>&1
if not errorlevel 1 (
    python3 --version >nul 2>&1
    if not errorlevel 1 (
        set "SYS_PY=python3"
        goto :python_found
    )
)

exit /b 1

:python_found
echo System Python found:
%SYS_PY% --version
echo.
exit /b 0


:ensure_venv
if exist "%VENV_PY%" (
    "%VENV_PY%" --version >nul 2>&1
    if not errorlevel 1 (
        echo Virtual environment found.
        echo.
        if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1
        exit /b 0
    )
)

if exist "%VENV_DIR%" (
    echo Invalid or broken virtual environment found.
    echo Removing virtual environment...
    rmdir /s /q "%VENV_DIR%" >nul 2>&1
)

echo Creating virtual environment...
%SYS_PY% -m venv "%VENV_DIR%" >"%LOG_FILE%" 2>&1

if errorlevel 1 (
    echo Failed to create virtual environment.
    type "%LOG_FILE%"
    exit /b 1
)

if not exist "%VENV_PY%" (
    echo Virtual environment Python was not created correctly.
    exit /b 1
)

"%VENV_PY%" --version >nul 2>&1
if errorlevel 1 (
    echo Virtual environment Python cannot be executed.
    exit /b 1
)

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1

echo Virtual environment created.
echo.
exit /b 0


:ensure_pip_light
echo Checking pip...

"%VENV_PY%" -m pip --version >nul 2>&1
if not errorlevel 1 (
    echo pip is available.
    echo.
    exit /b 0
)

echo pip is missing or broken.
echo Trying ensurepip...

"%VENV_PY%" -m ensurepip --upgrade >"%LOG_FILE%" 2>&1

"%VENV_PY%" -m pip --version >nul 2>&1
if not errorlevel 1 (
    echo pip restored.
    echo.
    exit /b 0
)

echo pip could not be restored with ensurepip.
echo Recreating virtual environment...

rmdir /s /q "%VENV_DIR%" >nul 2>&1

%SYS_PY% -m venv "%VENV_DIR%" >"%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo Failed to recreate virtual environment.
    type "%LOG_FILE%"
    exit /b 1
)

"%VENV_PY%" -m ensurepip --upgrade >"%LOG_FILE%" 2>&1
"%VENV_PY%" -m pip --version >nul 2>&1

if errorlevel 1 (
    echo pip could not be restored after recreating the virtual environment.
    type "%LOG_FILE%"
    exit /b 1
)

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1

echo pip restored after recreating virtual environment.
echo.
exit /b 0


:maybe_upgrade_tools
if not "%UPDATE_TOOLS%"=="1" (
    echo Packaging tools upgrade skipped.
    echo Use --update-tools to upgrade pip, setuptools and wheel.
    echo.
    exit /b 0
)

echo Option enabled: update packaging tools.
echo Upgrading pip, setuptools and wheel...

"%VENV_PY%" -m pip install --upgrade pip setuptools wheel >"%LOG_FILE%" 2>&1
if not errorlevel 1 (
    echo Packaging tools upgraded.
    echo.
    exit /b 0
)

echo Failed to upgrade packaging tools.
echo This operation is optional and usually not required to run the app.
type "%LOG_FILE%"
exit /b 1


rem ==================================================
rem Requirements management
rem ==================================================
:maybe_install_requirements
if not exist "%REQ_FILE%" (
    echo Requirements file not found.
    echo Skipping dependency installation.
    echo.
    exit /b 0
)

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1

call :get_file_hash "%REQ_FILE%" CURRENT_REQ_HASH
if errorlevel 1 (
    echo Could not calculate requirements hash.
    echo Installing requirements as a safe fallback...
    goto :install_requirements_now
)

set "PREVIOUS_REQ_HASH="
if exist "%REQ_HASH_FILE%" (
    set /p PREVIOUS_REQ_HASH=<"%REQ_HASH_FILE%"
)

if "%DEBUG_MODE%"=="1" (
    echo Debug:
    echo   Current req.txt hash : !CURRENT_REQ_HASH!
    echo   Previous saved hash  : !PREVIOUS_REQ_HASH!
    echo   Hash file            : %REQ_HASH_FILE%
    echo.
)

if "%FORCE_SETUP%"=="1" (
    echo Option enabled: force dependency installation.
    goto :install_requirements_now
)

if "!CURRENT_REQ_HASH!"=="!PREVIOUS_REQ_HASH!" (
    echo Requirements unchanged.
    echo Dependency installation skipped.
    echo.
    exit /b 0
)

echo Requirements changed or not installed yet.
echo Installing requirements...

:install_requirements_now
"%VENV_PY%" -m pip install -r "%REQ_FILE%" >"%LOG_FILE%" 2>&1
if not errorlevel 1 (
    call :save_current_requirements_hash
    if errorlevel 1 (
        echo Requirements installed, but launcher could not save req.txt hash.
        echo Next startup may reinstall requirements.
        echo.
        exit /b 0
    )

    echo Requirements installed.
    echo.
    exit /b 0
)

echo Failed to install requirements.
echo Trying one lightweight pip recovery, then retrying...

"%VENV_PY%" -m ensurepip --upgrade >>"%LOG_FILE%" 2>&1
"%VENV_PY%" -m pip install -r "%REQ_FILE%" >"%LOG_FILE%" 2>&1

if not errorlevel 1 (
    call :save_current_requirements_hash
    if errorlevel 1 (
        echo Requirements installed after pip recovery, but launcher could not save req.txt hash.
        echo Next startup may reinstall requirements.
        echo.
        exit /b 0
    )

    echo Requirements installed after pip recovery.
    echo.
    exit /b 0
)

echo Failed to install requirements.
type "%LOG_FILE%"
exit /b 1


:save_current_requirements_hash
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1

call :get_file_hash "%REQ_FILE%" SAVED_REQ_HASH
if errorlevel 1 exit /b 1

>"%REQ_HASH_FILE%" echo(!SAVED_REQ_HASH!

if "%DEBUG_MODE%"=="1" (
    echo Debug:
    echo   Saved req.txt hash: !SAVED_REQ_HASH!
    echo.
)

exit /b 0


:get_file_hash
set "HASH_FILE=%~1"
set "HASH_VAR=%~2"
set "%HASH_VAR%="

if not exist "%HASH_FILE%" exit /b 1

rem Prefer PowerShell because it is locale-independent.
where powershell >nul 2>&1
if not errorlevel 1 (
    set "PYLAUNCHKIT_HASH_FILE=%HASH_FILE%"
    for /f "usebackq delims=" %%H in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (Get-FileHash -Algorithm SHA256 -LiteralPath $env:PYLAUNCHKIT_HASH_FILE).Hash } catch { exit 1 }" 2^>nul`) do (
        set "%HASH_VAR%=%%H"
        set "PYLAUNCHKIT_HASH_FILE="
        exit /b 0
    )
    set "PYLAUNCHKIT_HASH_FILE="
)

rem Fallback to certutil.
rem This extracts only the hexadecimal hash line and ignores localized text.
for /f "tokens=* delims=" %%H in ('certutil -hashfile "%HASH_FILE%" SHA256 2^>nul ^| findstr /r /i /c:"^[0-9a-f][0-9a-f]*$"') do (
    set "%HASH_VAR%=%%H"
    exit /b 0
)

exit /b 1


rem ==================================================
rem Application execution
rem ==================================================
:run_application
if "%RUN_MODE%"=="module" (
    "%VENV_PY%" -m "%RUN_TARGET%" %APP_ARGS%
    exit /b %ERRORLEVEL%
)

if "%RUN_MODE%"=="file" (
    "%VENV_PY%" "%RUN_TARGET%" %APP_ARGS%
    exit /b %ERRORLEVEL%
)

exit /b 1


rem ==================================================
rem Fatal errors
rem ==================================================
:fatal_no_python
echo.
echo Python was not found.
echo Install Python and make sure it is available from PATH.
echo.
call :maybe_pause
exit /b 1

:fatal_venv
echo.
echo Failed to prepare the virtual environment.
echo See log file:
echo   %LOG_FILE%
echo.
call :maybe_pause
exit /b 1

:fatal_pip
echo.
echo Failed to prepare pip.
echo See log file:
echo   %LOG_FILE%
echo.
call :maybe_pause
exit /b 1

:fatal_requirements
echo.
echo Failed to install project requirements.
echo See log file:
echo   %LOG_FILE%
echo.
call :maybe_pause
exit /b 1

:fatal_entrypoint
echo.
echo Could not validate the Python entrypoint.
echo.
echo Current configuration:
echo   Mode  : %RUN_MODE%
echo   Target: %RUN_TARGET%
echo.
echo Examples:
echo   run.bat
echo   run.bat --module src.main

echo   run.bat --file main.py

echo   run.bat --mode file --target tools\script.py

echo.
call :maybe_pause
exit /b 1

:maybe_pause
if "%PAUSE_ON_ERROR%"=="1" pause
exit /b 0
