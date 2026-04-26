If WScript.Arguments.Count < 2 Then
    WScript.Quit 64
End If

Function Quote(value)
    Quote = Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function

Dim shell
Set shell = CreateObject("WScript.Shell")

Dim workDir
workDir = WScript.Arguments(0)
If Len(workDir) > 0 Then
    shell.CurrentDirectory = workDir
End If

Dim powerShellExe
powerShellExe = shell.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"

Dim command
command = Quote(powerShellExe) & " -NoLogo -NonInteractive -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File " & Quote(WScript.Arguments(1))

Dim i
For i = 2 To WScript.Arguments.Count - 1
    command = command & " " & Quote(WScript.Arguments(i))
Next

WScript.Quit shell.Run(command, 0, True)
