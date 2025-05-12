build {
  source "amazon-ebs.windows-server-2025" {
    name     = "buildbot-worker-windows-server-2025"
    ami_name = "buildbot-worker-windows-server-2025-1-${local.timestamp}"
  }

  provisioner "file" {
    sources     = ["../../scripts/"]
    destination = "C:/Windows/Temp/scripts/"
  }
  provisioner "file" {
    sources     = ["../../buildbot-host/buildbot.tac"]
    destination = "C:/Windows/Temp/"
  }
  provisioner "file" {
    sources     = ["build/"]
    destination = "C:/config"
  }
  provisioner "powershell" {
    inline = ["& 'C:/Program Files/Amazon/EC2Launch/EC2Launch.exe' status --block"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/base.ps1"]
  }
  provisioner "powershell" {
    elevated_password = var.windows_server_winrm_password
    elevated_user     = local.user_name
    inline            = ["C:/Windows/Temp/scripts/openssh.ps1 -configfiles C:\\config"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/git.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/cmake.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/python.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/pip.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/swig.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/vcpkg.ps1 -workdir C:\\Buildbot"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/pwsh.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/vsbuildtools.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/create-buildbot-user.ps1 -password ${var.windows_server_buildbot_user_password}"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/buildbot.ps1 -workdir C:\\Buildbot -buildmaster ${var.buildmaster_address} -workername windows-server-2025-latent-ec2 -workerpass ${var.windows_server_buildbot_worker_password} -user buildbot -password ${var.windows_server_buildbot_user_password}"]
  }
  # Required for some installers
  provisioner "windows-restart" {}
  provisioner "powershell" {
    # make sure to run user data scripts on first boot from AMI
    inline = ["& 'C:/Program Files/Amazon/EC2Launch/EC2Launch.exe' reset --clean"]
  }
}
