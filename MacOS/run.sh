#!/usr/bin/env bash
set -u

# PyLaunchKit - macOS Python project launcher.

PROJECT_NAME="PyLaunchKit"
DEFAULT_MODULE="src.main"

FORCE_SETUP=0
UPDATE_TOOLS=0
RECREATE_VENV=0
SHOW_HELP=0
DEBUG_MODE=0
PAUSE_ON_ERROR=0

RUN_MODE="module"
RUN_TARGET="$DEFAULT_MODULE"
RUN_FILE=""
MODULE_OPTION_USED=0
FILE_OPTION_USED=0
VENV_CREATED=0

SYS_PYTHON=""
APP_ARGS=()

resolve_launcher_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir=""
    local link_target=""

    while [ -h "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)" || return 1
        link_target="$(readlink "$source")" || return 1
        case "$link_target" in
            /*) source="$link_target" ;;
            *) source="$dir/$link_target" ;;
        esac
    done

    cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd
}

resolve_project_dir() {
    local base_name=""

    base_name="$(basename "$LAUNCHER_DIR")" || return 1
    case "$base_name" in
        MacOS|macOS|macos|Macos)
            cd -P "$LAUNCHER_DIR/.." >/dev/null 2>&1 && pwd
            ;;
        *)
            printf "%s\n" "$LAUNCHER_DIR"
            ;;
    esac
}

print_header() {
    echo "=================================================="
    echo "$PROJECT_NAME - Python project launcher"
    echo "=================================================="
    echo
}

show_help() {
    cat <<'EOF'
Usage:
  ./run.sh [launcher options] [-- app arguments]

Default execution:
  ./run.sh
  > python -m src.main

Launcher options:
  --module MODULE       Execute a Python module with: python -m MODULE
  --file FILE           Execute a Python file with: python FILE
  --force-setup         Reinstall dependencies from req.txt even if unchanged.
  --update-tools        Upgrade pip, setuptools and wheel.
  --recreate-venv       Delete and recreate the local .venv environment.
  --debug               Show launcher diagnostics.
  --pause-on-error      Wait for Enter before closing after an error.
  --help, -h            Show this help message.

Application arguments:
  Everything after -- is forwarded unchanged to the Python application.

Examples:
  ./run.sh
  ./run.sh --module src.cli
  ./run.sh --file tools/script.py
  ./run.sh --module src.cli -- --input "data/my file.txt"
  ./run.sh --file tools/script.py -- --verbose
  ./run.sh --force-setup
  ./run.sh --update-tools
  ./run.sh --recreate-venv
EOF
}

maybe_pause() {
    if [ "${PAUSE_ON_ERROR:-0}" = "1" ] && [ -t 0 ]; then
        printf "Press Enter to close..."
        IFS= read -r _ || true
    fi
}

die() {
    local message="$1"
    local code="${2:-1}"

    echo "Error: $message" >&2
    maybe_pause
    exit "$code"
}

parse_error() {
    local message="$1"

    echo "Error: $message" >&2
    echo >&2
    show_help >&2
    exit 1
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --)
                shift
                APP_ARGS=("$@")
                return 0
                ;;
            --force-setup)
                FORCE_SETUP=1
                shift
                ;;
            --update-tools)
                UPDATE_TOOLS=1
                shift
                ;;
            --recreate-venv)
                RECREATE_VENV=1
                shift
                ;;
            --debug)
                DEBUG_MODE=1
                shift
                ;;
            --pause-on-error)
                PAUSE_ON_ERROR=1
                shift
                ;;
            --help|-h)
                SHOW_HELP=1
                shift
                ;;
            --module)
                if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                    parse_error "Missing value for --module."
                fi
                case "$2" in
                    --*) parse_error "Missing value for --module." ;;
                esac
                if [ "$FILE_OPTION_USED" = "1" ]; then
                    parse_error "Cannot use --module and --file together."
                fi
                MODULE_OPTION_USED=1
                RUN_MODE="module"
                RUN_TARGET="$2"
                shift 2
                ;;
            --module=*)
                if [ "$FILE_OPTION_USED" = "1" ]; then
                    parse_error "Cannot use --module and --file together."
                fi
                RUN_TARGET="${1#--module=}"
                if [ -z "$RUN_TARGET" ]; then
                    parse_error "Missing value for --module."
                fi
                case "$RUN_TARGET" in
                    --*) parse_error "Missing value for --module." ;;
                esac
                MODULE_OPTION_USED=1
                RUN_MODE="module"
                shift
                ;;
            --file)
                if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                    parse_error "Missing value for --file."
                fi
                case "$2" in
                    --*) parse_error "Missing value for --file." ;;
                esac
                if [ "$MODULE_OPTION_USED" = "1" ]; then
                    parse_error "Cannot use --module and --file together."
                fi
                FILE_OPTION_USED=1
                RUN_MODE="file"
                RUN_TARGET="$2"
                shift 2
                ;;
            --file=*)
                if [ "$MODULE_OPTION_USED" = "1" ]; then
                    parse_error "Cannot use --module and --file together."
                fi
                RUN_TARGET="${1#--file=}"
                if [ -z "$RUN_TARGET" ]; then
                    parse_error "Missing value for --file."
                fi
                case "$RUN_TARGET" in
                    --*) parse_error "Missing value for --file." ;;
                esac
                FILE_OPTION_USED=1
                RUN_MODE="file"
                shift
                ;;
            --*)
                echo "Error: Unknown launcher option: $1" >&2
                echo >&2
                echo "Application arguments must be placed after --" >&2
                echo "Example:" >&2
                echo "  ./run.sh --module src.main -- --name Mario --verbose" >&2
                echo >&2
                show_help >&2
                exit 1
                ;;
            *)
                echo "Error: Unknown launcher argument: $1" >&2
                echo >&2
                echo "Application arguments must be placed after --" >&2
                echo "Example:" >&2
                echo "  ./run.sh --module src.main -- --name Mario --verbose" >&2
                echo >&2
                show_help >&2
                exit 1
                ;;
        esac
    done
}

validate_entrypoint_options() {
    case "$RUN_MODE" in
        module)
            if [ -z "$RUN_TARGET" ]; then
                die "Module target cannot be empty."
            fi
            ;;
        file)
            if [ -z "$RUN_TARGET" ]; then
                die "File target cannot be empty."
            fi
            case "$RUN_TARGET" in
                /*) RUN_FILE="$RUN_TARGET" ;;
                *) RUN_FILE="$PROJECT_DIR/$RUN_TARGET" ;;
            esac
            ;;
        *)
            die "Invalid run mode: $RUN_MODE"
            ;;
    esac
}

find_system_python() {
    local candidate=""

    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            if "$candidate" -c 'import sys, venv; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
                SYS_PYTHON="$candidate"
                echo "System Python found:"
                "$SYS_PYTHON" --version
                echo
                return 0
            fi
        fi
    done

    return 1
}

remove_venv() {
    if [ -z "$VENV_DIR" ] || [ -z "$PROJECT_DIR" ]; then
        die "Refusing to remove virtual environment because paths are empty."
    fi
    if [ "$VENV_DIR" != "$PROJECT_DIR/.venv" ]; then
        die "Refusing to remove unexpected virtual environment path: $VENV_DIR"
    fi
    if [ "$(basename "$VENV_DIR")" != ".venv" ]; then
        die "Refusing to remove unexpected virtual environment path: $VENV_DIR"
    fi

    if [ -e "$VENV_DIR" ] || [ -L "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
    fi
}

create_venv() {
    echo "Creating virtual environment..."

    "$SYS_PYTHON" -m venv "$VENV_DIR" >"$LOG_FILE" 2>&1
    if [ "$?" -ne 0 ]; then
        echo "Failed to create virtual environment."
        cat "$LOG_FILE"
        return 1
    fi

    if [ ! -x "$VENV_PYTHON" ]; then
        echo "Virtual environment Python was not created correctly."
        return 1
    fi

    "$VENV_PYTHON" --version >/dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        echo "Virtual environment Python cannot be executed."
        return 1
    fi

    VENV_CREATED=1
    echo "Virtual environment created."
    echo
    return 0
}

ensure_venv() {
    if [ -x "$VENV_PYTHON" ]; then
        "$VENV_PYTHON" --version >/dev/null 2>&1
        if [ "$?" -eq 0 ]; then
            echo "Virtual environment found."
            echo
            return 0
        fi
    fi

    if [ -e "$VENV_DIR" ] || [ -L "$VENV_DIR" ]; then
        echo "Invalid or broken virtual environment found:"
        echo "  $VENV_DIR"
        echo "Use --recreate-venv to delete and recreate it."
        return 1
    fi

    find_system_python || return 1
    create_venv
}

recreate_venv() {
    echo "Option enabled: recreate virtual environment."
    echo "Removing virtual environment..."
    remove_venv
    echo

    find_system_python || return 1
    create_venv
}

ensure_pip_light() {
    echo "Checking pip..."

    "$VENV_PYTHON" -m pip --version >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "pip is available."
        echo
        return 0
    fi

    echo "pip is missing or broken."
    echo "Trying ensurepip..."
    "$VENV_PYTHON" -m ensurepip --upgrade >"$LOG_FILE" 2>&1

    "$VENV_PYTHON" -m pip --version >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "pip restored."
        echo
        return 0
    fi

    echo "pip could not be restored with ensurepip."
    echo "Use --recreate-venv to rebuild the virtual environment."
    cat "$LOG_FILE"
    return 1
}

maybe_upgrade_tools() {
    if [ "$UPDATE_TOOLS" != "1" ]; then
        echo "Packaging tools upgrade skipped."
        echo "Use --update-tools to upgrade pip, setuptools and wheel."
        echo
        return 0
    fi

    echo "Option enabled: update packaging tools."
    echo "Upgrading pip, setuptools and wheel..."

    "$VENV_PYTHON" -m pip install --upgrade pip setuptools wheel >"$LOG_FILE" 2>&1
    if [ "$?" -eq 0 ]; then
        echo "Packaging tools upgraded."
        echo
        return 0
    fi

    echo "Failed to upgrade packaging tools."
    cat "$LOG_FILE"
    return 1
}

calculate_file_hash() {
    local file="$1"
    local line=""

    if command -v shasum >/dev/null 2>&1; then
        line="$(shasum -a 256 "$file" 2>/dev/null)" || return 1
        printf "%s\n" "${line%% *}"
        return 0
    fi

    if command -v openssl >/dev/null 2>&1; then
        line="$(openssl dgst -sha256 "$file" 2>/dev/null)" || return 1
        printf "%s\n" "${line##* }"
        return 0
    fi

    return 1
}

save_requirements_hash() {
    local hash_value="$1"

    if [ -z "$hash_value" ]; then
        return 1
    fi
    mkdir -p "$STATE_DIR" || return 1
    printf "%s\n" "$hash_value" >"$REQ_HASH_FILE"
}

install_requirements_now() {
    local hash_value="$1"

    if [ -z "$hash_value" ]; then
        echo "Internal error: requirements hash is empty."
        return 1
    fi

    "$VENV_PYTHON" -m pip install -r "$REQ_FILE" >"$LOG_FILE" 2>&1
    if [ "$?" -eq 0 ]; then
        if ! save_requirements_hash "$hash_value"; then
            echo "Requirements installed, but launcher could not save req.txt hash."
            echo "Dependency state is not reliable; see:"
            echo "  $REQ_HASH_FILE"
            return 1
        fi
        echo "Requirements installed."
        echo
        return 0
    fi

    echo "Failed to install requirements."
    echo "Trying one lightweight pip recovery, then retrying..."

    "$VENV_PYTHON" -m ensurepip --upgrade >>"$LOG_FILE" 2>&1
    "$VENV_PYTHON" -m pip install -r "$REQ_FILE" >>"$LOG_FILE" 2>&1

    if [ "$?" -eq 0 ]; then
        if ! save_requirements_hash "$hash_value"; then
            echo "Requirements installed after pip recovery, but launcher could not save req.txt hash."
            echo "Dependency state is not reliable; see:"
            echo "  $REQ_HASH_FILE"
            return 1
        fi
        echo "Requirements installed after pip recovery."
        echo
        return 0
    fi

    echo "Failed to install requirements."
    cat "$LOG_FILE"
    return 1
}

maybe_install_requirements() {
    local current_hash=""
    local previous_hash=""

    if [ ! -f "$REQ_FILE" ]; then
        echo "Requirements file not found."
        echo "Skipping dependency installation."
        echo
        return 0
    fi

    current_hash="$(calculate_file_hash "$REQ_FILE")" || {
        echo "Could not calculate requirements hash."
        echo "macOS should provide shasum; openssl is also accepted as fallback."
        return 1
    }

    if [ -f "$REQ_HASH_FILE" ]; then
        previous_hash="$(tr -d '[:space:]' <"$REQ_HASH_FILE")" || previous_hash=""
    fi

    if [ "$DEBUG_MODE" = "1" ]; then
        echo "Debug:"
        echo "  Launcher dir     : $LAUNCHER_DIR"
        echo "  Project dir      : $PROJECT_DIR"
        echo "  Current req hash : $current_hash"
        echo "  Previous req hash: ${previous_hash:-<none>}"
        echo "  Hash file        : $REQ_HASH_FILE"
        echo
    fi

    if [ "$FORCE_SETUP" = "1" ]; then
        echo "Option enabled: force dependency installation."
        install_requirements_now "$current_hash"
        return "$?"
    fi

    if [ "$VENV_CREATED" = "1" ]; then
        echo "Virtual environment is new."
        echo "Installing requirements..."
        install_requirements_now "$current_hash"
        return "$?"
    fi

    if [ "$current_hash" = "$previous_hash" ]; then
        echo "Requirements unchanged."
        echo "Dependency installation skipped."
        echo
        return 0
    fi

    echo "Requirements changed or not installed yet."
    echo "Installing requirements..."
    install_requirements_now "$current_hash"
}

validate_entrypoint_runtime() {
    if [ "$RUN_MODE" = "file" ]; then
        if [ ! -f "$RUN_FILE" ]; then
            echo "Python file not found:"
            echo "  $RUN_FILE"
            return 1
        fi
        return 0
    fi

    "$VENV_PYTHON" -c 'import importlib.util, sys; sys.exit(0 if importlib.util.find_spec(sys.argv[1]) else 1)' "$RUN_TARGET" >/dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        echo "Python module not found or not importable:"
        echo "  $RUN_TARGET"
        echo
        echo "Default expected project file:"
        echo "  $PROJECT_DIR/src/main.py"
        return 1
    fi

    return 0
}

print_debug_info() {
    echo "Debug:"
    echo "  Launcher dir     : $LAUNCHER_DIR"
    echo "  Project dir      : $PROJECT_DIR"
    echo "  Virtual env      : $VENV_DIR"
    echo "  Python executable: $VENV_PYTHON"
    echo "  Run mode         : $RUN_MODE"
    echo "  Run target       : $RUN_TARGET"
    if [ "${#APP_ARGS[@]}" -eq 0 ]; then
        echo "  App arguments    : <none>"
    else
        printf "  App arguments    :"
        printf " %q" "${APP_ARGS[@]}"
        printf "\n"
    fi
    echo
}

run_application() {
    local exit_code=0

    echo "Starting application..."
    echo

    if [ -t 1 ] && command -v clear >/dev/null 2>&1; then
        clear
    fi

    if [ "$RUN_MODE" = "module" ]; then
        "$VENV_PYTHON" -m "$RUN_TARGET" "${APP_ARGS[@]}"
        exit_code="$?"
    else
        "$VENV_PYTHON" "$RUN_FILE" "${APP_ARGS[@]}"
        exit_code="$?"
    fi

    if [ "$exit_code" -ne 0 ]; then
        echo
        echo "The application exited with an error."
        echo "Exit code: $exit_code"
        echo
    fi

    return "$exit_code"
}

LAUNCHER_DIR="$(resolve_launcher_dir)" || {
    echo "Error: could not determine the launcher directory." >&2
    exit 1
}

PROJECT_DIR="$(resolve_project_dir)" || {
    echo "Error: could not determine the project directory." >&2
    exit 1
}

VENV_DIR="$PROJECT_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
REQ_FILE="$PROJECT_DIR/req.txt"
STATE_DIR="$VENV_DIR/.launcher"
REQ_HASH_FILE="$STATE_DIR/req.txt.sha256"
LOG_FILE="$PROJECT_DIR/run.log"

parse_args "$@"

if [ "$SHOW_HELP" = "1" ]; then
    show_help
    exit 0
fi

validate_entrypoint_options

cd "$PROJECT_DIR" || die "Could not enter project directory: $PROJECT_DIR"

print_header

if [ "$RECREATE_VENV" = "1" ]; then
    recreate_venv || {
        echo
        echo "Failed to recreate the virtual environment."
        echo "See log file:"
        echo "  $LOG_FILE"
        echo
        maybe_pause
        exit 1
    }
else
    ensure_venv || {
        echo
        echo "Failed to prepare the virtual environment."
        echo "If an existing .venv is broken, run with --recreate-venv."
        echo "See log file:"
        echo "  $LOG_FILE"
        echo
        maybe_pause
        exit 1
    }
fi

ensure_pip_light || {
    echo
    echo "Failed to prepare pip."
    echo "See log file:"
    echo "  $LOG_FILE"
    echo
    maybe_pause
    exit 1
}

maybe_upgrade_tools || {
    echo
    echo "Failed to prepare packaging tools."
    echo "See log file:"
    echo "  $LOG_FILE"
    echo
    maybe_pause
    exit 1
}

maybe_install_requirements || {
    echo
    echo "Failed to install project requirements."
    echo "See log file:"
    echo "  $LOG_FILE"
    echo
    maybe_pause
    exit 1
}

validate_entrypoint_runtime || {
    echo
    echo "Could not validate the Python entrypoint."
    echo
    echo "Current configuration:"
    echo "  Mode  : $RUN_MODE"
    echo "  Target: $RUN_TARGET"
    echo
    echo "Examples:"
    echo "  ./run.sh"
    echo "  ./run.sh --module src.main"
    echo "  ./run.sh --file src/main.py"
    echo
    maybe_pause
    exit 1
}

if [ "$DEBUG_MODE" = "1" ]; then
    print_debug_info
fi

run_application
APP_EXIT_CODE="$?"

if [ "$APP_EXIT_CODE" -ne 0 ]; then
    maybe_pause
fi

exit "$APP_EXIT_CODE"
