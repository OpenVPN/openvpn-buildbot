param ([string] $workdir,
       [string] $openvpn_build_ref = "master",
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
    & git.exe clone -b $openvpn_build_ref https://github.com/OpenVPN/openvpn-build.git $openvpn_build
    if ($debug -eq $true) { CheckLastExitCode }
    & git.exe -C $openvpn_build submodule update --init
    if ($debug -eq $true) { CheckLastExitCode }
}

& $PSScriptRoot\vcpkg.ps1 -workdir "${openvpn_build}\src" -debug:$debug

cd "${openvpn_build}\src\vcpkg"

# Install OpenVPN build dependencies
$architectures = @('x64','x86','arm64')
ForEach ($arch in $architectures) {
    # openssl:${arch}-windows is required for openvpn-gui builds
    & .\vcpkg.exe `
        --overlay-ports "${openvpn_build}\src\openvpn\contrib\vcpkg-ports" `
        --overlay-ports "${openvpn_build}\windows-msi\vcpkg-ports" `
	--overlay-triplets "${openvpn_build}\src\openvpn\contrib\vcpkg-triplets" `
	install --triplet "${arch}-windows-ovpn" json-c lz4 lzo openssl pkcs11-helper tap-windows6 "openssl:${arch}-windows"

    & .\vcpkg.exe `
        --overlay-ports "${openvpn_build}\src\openvpn\contrib\vcpkg-ports" `
        --overlay-ports "${openvpn_build}\windows-msi\vcpkg-ports" `
	--overlay-triplets "${openvpn_build}\src\openvpn\contrib\vcpkg-triplets" `
        upgrade --no-dry-run

    & .\vcpkg.exe integrate install
}

# Ensure that we can convert the man page from rst to html
& pip.exe --no-cache-dir install docutils
