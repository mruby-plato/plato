set args = WScript.Arguments

if args.Count = 0 then
    WScript.Echo "Usage: wscirpt shortcut.vbs <plato_path>" + chr(13) + "  plato_path: Plato base directory"
    WScript.Quit
end if

set objShell = WScript.CreateObject("WScript.Shell")
' Create shortcut on Desktop
strDesktop = objShell.SpecialFolders("Desktop")
strFileName = strDesktop + "\Plato2 IDE.lnk"
set objShortcut = objShell.CreateShortcut(strFileName)
objShortcut.TargetPath = args(0) + "\.plato\plato2-win32-ia32\plato2.exe"
objShortcut.Save
' Create `Plato` shortcut into install directory
strFileName = args(0) + "\Plato2 IDE.lnk"
set objShortcut = objShell.CreateShortcut(strFileName)
objShortcut.TargetPath = args(0) + "\.plato\plato2-win32-ia32\plato2.exe"
objShortcut.Save
' Create `Plato-viewer.html` shortcut into install directory
strFileName = args(0) + "\plato-viewer.lnk"
set objShortcut = objShell.CreateShortcut(strFileName)
objShortcut.TargetPath = args(0) + "\.plato\tools\plato-viewer.html"
objShortcut.Save
' Create `bt-checker.html` shortcut into install directory
strFileName = args(0) + "\bt-checker.lnk"
set objShortcut = objShell.CreateShortcut(strFileName)
objShortcut.TargetPath = args(0) + "\.plato\tools\bt-checker.html"
objShortcut.Save
