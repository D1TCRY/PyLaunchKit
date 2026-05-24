Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
 
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strBatch = strPath & "\run.bat"
 
objShell.CurrentDirectory = strPath
 
' 0 = finestra nascosta
' False = non aspetta la fine del programma
objShell.Run Chr(34) & strBatch & Chr(34), 0, False
 
Set objShell = Nothing
Set objFSO = Nothing