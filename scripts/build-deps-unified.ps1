param ([string] $workdir,
       [string] $configfiles,
       [switch] $debug)

if ($debug -eq $true) {
  . $PSScriptRoot\ps_support.ps1
}

Write-Host "Setting up openvpn build dependencies with vcpkg"

if (-Not (Test-Path $workdir)) {
  New-Item -Type directory $workdir
  if ($debug -eq $true) { CheckLastExitCode }
}

Add-MpPreference -ExclusionPath $workdir
if ($debug -eq $true) { CheckLastExitCode }

$openvpn_build = "${workdir}\openvpn-build"
if (-Not (Test-Path $openvpn_build)) {
    & git.exe clone https://github.com/OpenVPN/openvpn-build.git $openvpn_build
    if ($debug -eq $true) { CheckLastExitCode }
    & git.exe -C $openvpn_build submodule update --init
    if ($debug -eq $true) { CheckLastExitCode }
}

& $PSScriptRoot\vcpkg.ps1 -workdir "${openvpn_build}\src" -debug:$debug

# Ensure that we can convert the man page from rst to html
& pip.exe --no-cache-dir install docutils
