param ([string] $workdir,
       [string] $jenkins,
       [string] $user,
       [string] $password,
       [bool]   $ignore_ssl_errors=$false)

. C:\Windows\Temp\scripts\ps_support.ps1

Write-Host "Setting up Jenkins agent"

& choco.exe install -y openjdk17
CheckLastExitCode

if (-Not (Test-Path $workdir)) {
  New-Item -Type directory $workdir
}

Add-MpPreference -ExclusionPath $workdir
CheckLastExitCode

if ($ignore_ssl_errors) {
  add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
Invoke-WebRequest -Uri "https://${jenkins}/jnlpJars/agent.jar" -Outfile "${workdir}/agent.jar"
CheckLastExitCode

Write-Host "Installing vswhere.exe to used by build steps"
& choco.exe install -y vswhere
CheckLastExitCode

Write-Host "Configuring jenkins agent to launch at boot time"
& choco.exe install -y nssm
CheckLastExitCode

& nssm.exe install jenkins-agent java
CheckLastExitCode

& nssm.exe set jenkins-agent AppParameters "-jar agent.jar -jnlpUrl https://${jenkins}/computer/DUMMYAGENT/jenkins-agent.jnlp -secret DUMMYSECRET -workDir $workdir"
& nssm.exe set jenkins-agent AppDirectory $workdir
& nssm.exe set jenkins-agent AppExit Default Restart
& nssm.exe set jenkins-agent AppStdout "${workdir}/agent-service.log"
& nssm.exe set jenkins-agent AppStderr "${workdir}/agent-service.log"
& nssm.exe set jenkins-agent AppRotateFiles 1
& nssm.exe set jenkins-agent AppRotateBytes 1073741824
& nssm.exe set jenkins-agent DisplayName jenkins-agent
& nssm.exe set jenkins-agent ObjectName ".\${user}" "${password}"
& nssm.exe set jenkins-agent Start SERVICE_AUTO_START
& nssm.exe set jenkins-agent Type SERVICE_WIN32_OWN_PROCESS

Start-Service jenkins-agent
CheckLastExitCode
