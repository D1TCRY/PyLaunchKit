#!/usr/bin/env bash
set -u

# PyLaunchKit terminal launcher for macOS.
# Finder opens .command files in Terminal. Make this file executable first:
#   chmod +x MacOS/run_terminal.command

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

LAUNCHER_DIR="$(resolve_launcher_dir)" || {
    echo "Error: could not determine the launcher directory." >&2
    exit 1
}

RUN_SH="$LAUNCHER_DIR/run.sh"

if [ ! -f "$RUN_SH" ]; then
    echo "Error: run.sh was not found next to run_terminal.command." >&2
    echo "Expected path:"
    echo "  $RUN_SH"
    exit 1
fi

/usr/bin/env bash "$RUN_SH" "$@"
EXIT_CODE="$?"

if [ "${PYLAUNCHKIT_KEEP_TERMINAL:-0}" = "1" ]; then
    echo
    echo "PyLaunchKit finished with exit code: $EXIT_CODE"
    printf "Press Enter to close..."
    IFS= read -r _ || true
fi

exit "$EXIT_CODE"
