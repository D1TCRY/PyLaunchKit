-- PyLaunchKit GUI launcher for macOS.
--
-- This script starts MacOS/run.sh through do shell script without keeping a
-- Terminal window attached to the Python process.
--
-- Notes:
-- - A .command file opened from Finder still opens Terminal briefly.
-- - Compile this file as MacOS/run_gui.app for a cleaner double-click GUI flow:
--     osacompile -o MacOS/run_gui.app MacOS/run_gui.applescript
-- - Arguments are forwarded when launched through osascript/run_gui.command.
--   A plain double-click on a compiled app normally provides no CLI arguments.
-- - The Python process is started in the background. This launcher reports
--   AppleScript launch success; application output goes to run_gui.log.

on run argv
    set launcherDir to ""
    set forwardedArgs to {}

    if (count of argv) > 0 then
        set launcherDir to item 1 of argv
        if (count of argv) > 1 then
            set forwardedArgs to items 2 thru -1 of argv
        end if
    else
        set launcherDir to my currentContainerDir()
    end if

    set projectDir to my projectDirFromLauncherDir(launcherDir)
    set runPath to launcherDir & "/run.sh"
    set logPath to projectDir & "/run_gui.log"

    try
        do shell script "/bin/test -f " & quoted form of runPath
    on error
        error "run.sh was not found: " & runPath
    end try

    set commandText to "cd " & quoted form of projectDir & " && /usr/bin/nohup /usr/bin/env bash " & quoted form of runPath

    repeat with oneArg in forwardedArgs
        set commandText to commandText & " " & quoted form of (contents of oneArg)
    end repeat

    set commandText to commandText & " > " & quoted form of logPath & " 2>&1 &"
    do shell script commandText
end run

on currentContainerDir()
    set scriptPath to POSIX path of (path to me)
    if scriptPath ends with "/" then
        set scriptPath to text 1 thru -2 of scriptPath
    end if
    return do shell script "/usr/bin/dirname " & quoted form of scriptPath
end currentContainerDir

on projectDirFromLauncherDir(launcherDir)
    set baseName to do shell script "/usr/bin/basename " & quoted form of launcherDir
    if baseName is "MacOS" or baseName is "macOS" or baseName is "macos" or baseName is "Macos" then
        return do shell script "/usr/bin/dirname " & quoted form of launcherDir
    end if
    return launcherDir
end projectDirFromLauncherDir
