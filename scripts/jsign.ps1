param ([string] $workdir,
       [string] $configfiles)

. C:\Windows\Temp\scripts\ps_support.ps1

Write-Host "Setting up gcloud and jsign"

& choco.exe install -y openjdk17
CheckLastExitCode

Invoke-WebRequest -Uri "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe" -Outfile "C:\Windows\Temp\GoogleCloudSDKInstaller.exe"

& "C:\Windows\Temp\GoogleCloudSDKInstaller.exe" /S /allusers
CheckLastExitCode

Invoke-WebRequest -Uri "https://github.com/ebourg/jsign/releases/download/6.0/jsign-6.0.jar" -Outfile "${workdir}/jsign.jar"

Copy-Item "${configfiles}\signingCert.pem" "${workdir}" -Force
Copy-Item "${configfiles}\clientLibraryConfig.json" "${workdir}" -Force
