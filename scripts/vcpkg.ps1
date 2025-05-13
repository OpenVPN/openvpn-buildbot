param ([string] $workdir,
       [switch] $debug)

if ($debug -eq $true) {
  . $PSScriptRoot\ps_support.ps1
}

# Required for vcpkg (it will download it automatically, but avoid that overhead)
Write-Host "Installing 7zip"
& choco.exe install -y 7zip

# Required for S3 binary caching
Write-Host "Installing and setting up aws CLI"

Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -Outfile C:\AWSCLIV2.msi

Start-Process msiexec.exe -ArgumentList '/i C:\AWSCLIV2.msi /quiet /norestart /log C:\cli-install.txt' -Wait
if ($debug -eq $true) { CheckLastExitCode }

if (-Not (Test-Path $workdir)) {
  New-Item -Type directory $workdir
  if ($debug -eq $true) { CheckLastExitCode }
}

Write-Host "Installing and setting up vcpkg"

if (-Not (Test-Path "${workdir}\vcpkg")) {
  & git.exe clone https://github.com/microsoft/vcpkg.git "${workdir}\vcpkg"
  if ($debug -eq $true) { CheckLastExitCode }
}

# Bootstrap vcpkg
& "${workdir}\vcpkg\bootstrap-vcpkg.bat"

# Update ports
cd "${workdir}\vcpkg"
& git.exe pull
if ($debug -eq $true) { CheckLastExitCode }

# Ensure that OpenVPN build can find the dependencies
& "${workdir}\vcpkg\vcpkg.exe" integrate install
