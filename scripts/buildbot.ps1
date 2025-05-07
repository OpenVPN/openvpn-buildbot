param ([string] $workdir,
       [string] $buildmaster,
       [string] $workername,
       [string] $workerpass,
       [string] $user,
       [string] $password)

Write-Host "Setting up buildbot"

& pip.exe --no-cache-dir install twisted[tls]
& pip.exe --no-cache-dir install pywin32
& pip.exe --no-cache-dir install buildbot_worker==3.11.9
if (-Not (Test-Path $workdir)) {
  New-item -Type directory $workdir
}
Copy-Item "C:\Windows\Temp\buildbot.tac" $workdir

Write-Host "Installing vswhere.exe to used by build steps"
& choco.exe install -y vswhere

Write-Host "Configuring buildbot to launch at boot time"
& choco.exe install -y nssm
& nssm.exe install buildbot-worker C:\Python312\Scripts\twistd.exe
& nssm.exe set buildbot-worker AppParameters "--nodaemon --python=buildbot.tac"
& nssm.exe set buildbot-worker AppDirectory $workdir
& nssm.exe set buildbot-worker AppExit Default Restart
& nssm.exe set buildbot-worker AppEnvironmentExtra :WORKERNAME=$workername
& nssm.exe set buildbot-worker AppEnvironmentExtra +WORKERPASS=$workerpass
& nssm.exe set buildbot-worker AppEnvironmentExtra +BUILDMASTER=$buildmaster
& nssm.exe set buildbot-worker AppEnvironmentExtra +VCPKG_ROOT="${workdir}\vcpkg"
& nssm.exe set buildbot-worker AppStdout "${workdir}/twistd.log"
& nssm.exe set buildbot-worker AppStderr "${workdir}/twistd.log"
& nssm.exe set buildbot-worker AppRotateFiles 1
& nssm.exe set buildbot-worker AppRotateBytes 1073741824
& nssm.exe set buildbot-worker DisplayName buildbot-worker
& nssm.exe set buildbot-worker ObjectName ".\${user}" "${password}"
& nssm.exe set buildbot-worker Start SERVICE_AUTO_START
& nssm.exe set buildbot-worker Type SERVICE_WIN32_OWN_PROCESS

Start-Service buildbot-worker
