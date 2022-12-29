param ([string] $configfiles)

Write-Host "Installing OpenSSH"

. $PSScriptRoot\ps_support.ps1

Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
CheckLastExitCode
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
CheckLastExitCode
# Creates config files
Start-Service sshd
CheckLastExitCode
# Allow to edit config files
Stop-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
CheckLastExitCode

Copy-Item "${configfiles}\sshd_config" C:\ProgramData\ssh\ -Force
CheckLastExitCode

Copy-Item "${configfiles}\administrators_authorized_keys" c:\ProgramData\ssh\administrators_authorized_keys
CheckLastExitCode

icacls C:\ProgramData\ssh\administrators_authorized_keys /reset
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant:r administrators:f
CheckLastExitCode
icacls C:\ProgramData\ssh\administrators_authorized_keys /grant system:f
CheckLastExitCode

Start-Service sshd
