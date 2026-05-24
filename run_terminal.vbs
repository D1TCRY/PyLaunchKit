Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
 
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strBatch = strPath & "\run.bat"
 
objShell.CurrentDirectory = strPath
 
objShell.Run "cmd.exe /c " & Chr(34) & strBatch & Chr(34), 1, True
 
Set objShell = Nothing
Set objFSO = Nothing
