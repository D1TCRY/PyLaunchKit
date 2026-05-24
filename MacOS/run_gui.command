#!/usr/bin/env bash
set -u

# PyLaunchKit GUI launcher for macOS.
# A .command file opened from Finder still opens Terminal briefly. This wrapper
# delegates to AppleScript so run.sh can continue without a persistent terminal.
# For the cleanest double-click GUI launcher, compile the AppleScript:
#   osacompile -o MacOS/run_gui.app MacOS/run_gui.applescript

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
APPLESCRIPT="$LAUNCHER_DIR/run_gui.applescript"

if [ ! -f "$RUN_SH" ]; then
    echo "Error: run.sh was not found next to run_gui.command." >&2
    echo "Expected path:"
    echo "  $RUN_SH"
    exit 1
fi

if [ -f "$APPLESCRIPT" ] && command -v osascript >/dev/null 2>&1; then
    /usr/bin/osascript "$APPLESCRIPT" "$LAUNCHER_DIR" "$@"
    exit "$?"
fi

echo "Warning: run_gui.applescript or osascript was not available."
echo "Falling back to visible terminal execution."
/usr/bin/env bash "$RUN_SH" "$@"
exit "$?"
