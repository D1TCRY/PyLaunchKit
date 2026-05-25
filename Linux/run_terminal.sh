#!/usr/bin/env bash
set -u
set -o pipefail 2>/dev/null || true

# PyLaunchKit - Linux terminal launcher wrapper.
#
# Make this file executable before using it directly:
#   chmod +x run_terminal.sh
#
# The wrapper opens a supported terminal emulator, runs run.sh, and keeps the
# terminal open only when the application exits with an error.

resolve_script_dir() {
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

    base_name="$(basename "$SCRIPT_DIR")" || return 1
    case "$base_name" in
        Linux|linux)
            cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd
            ;;
        *)
            printf "%s\n" "$SCRIPT_DIR"
            ;;
    esac
}

create_terminal_script() {
    local tmp_script=""

    tmp_script="$(mktemp "${TMPDIR:-/tmp}/pylaunchkit-terminal.XXXXXX.sh")" || return 1

    {
        printf "%s\n" "#!/usr/bin/env bash"
        printf "%s\n" "set +e"
        printf "cd %q || exit 1\n" "$PROJECT_DIR"
        printf "/usr/bin/env bash %q" "$RUN_SH"
        local arg=""
        for arg in "$@"; do
            printf " %q" "$arg"
        done
        printf "\n"
        cat <<'EOF'
status=$?
if [ "$status" -ne 0 ]; then
    echo
    echo "PyLaunchKit exited with an error."
    echo "Exit code: $status"
    echo
    if [ -t 0 ]; then
        printf "Press Enter to close..."
        IFS= read -r _ || true
        echo
    fi
fi
rm -f -- "$0"
exit "$status"
EOF
    } >"$tmp_script" || {
        rm -f -- "$tmp_script"
        return 1
    }

    chmod +x "$tmp_script" || {
        rm -f -- "$tmp_script"
        return 1
    }

    printf "%s\n" "$tmp_script"
}

launch_with_terminal() {
    local terminal_script="$1"

    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- "$terminal_script" && return 0
    fi

    if command -v konsole >/dev/null 2>&1; then
        konsole -e "$terminal_script" && return 0
    fi

    if command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal --command "$terminal_script" && return 0
    fi

    if command -v mate-terminal >/dev/null 2>&1; then
        mate-terminal -- "$terminal_script" && return 0
    fi

    if command -v kitty >/dev/null 2>&1; then
        kitty "$terminal_script" && return 0
    fi

    if command -v alacritty >/dev/null 2>&1; then
        alacritty -e "$terminal_script" && return 0
    fi

    if command -v xterm >/dev/null 2>&1; then
        xterm -e "$terminal_script" && return 0
    fi

    return 1
}

SCRIPT_DIR="$(resolve_script_dir)" || {
    echo "Error: could not determine the launcher directory." >&2
    exit 1
}

PROJECT_DIR="$(resolve_project_dir)" || {
    echo "Error: could not determine the project directory." >&2
    exit 1
}

RUN_SH="$SCRIPT_DIR/run.sh"

if [ ! -f "$RUN_SH" ]; then
    echo "Error: run.sh was not found next to run_terminal.sh:" >&2
    echo "  $RUN_SH" >&2
    exit 1
fi

TERMINAL_SCRIPT="$(create_terminal_script "$@")" || {
    echo "Error: could not create temporary terminal launcher." >&2
    exit 1
}

if launch_with_terminal "$TERMINAL_SCRIPT"; then
    exit 0
fi

rm -f -- "$TERMINAL_SCRIPT"

if [ -t 0 ]; then
    echo "No supported terminal emulator was found."
    echo "Running in the current terminal instead."
    echo
    exec /usr/bin/env bash "$RUN_SH" "$@"
fi

echo "Error: no supported terminal emulator was found." >&2
echo "Install one of: gnome-terminal, konsole, xfce4-terminal, mate-terminal, kitty, alacritty, xterm." >&2
exit 127
