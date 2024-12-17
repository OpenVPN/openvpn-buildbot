param ([string] $workdir)

. C:\Windows\Temp\scripts\ps_support.ps1

Write-Host "Setting up Jenkins agent (SSH)"

& choco.exe install -y openjdk17
CheckLastExitCode

if (-Not (Test-Path $workdir)) {
  New-Item -Type directory $workdir
}

Add-MpPreference -ExclusionPath $workdir
CheckLastExitCode
