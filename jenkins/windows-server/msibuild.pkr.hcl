build {
  source "amazon-ebs.windows-server-2022" {
    name     = "msibuild-windows-server-2022-2.6"
    ami_name = "msibuild-windows-server-2022-2.6-6"
  }

  provisioner "file" {
    sources     = ["../../scripts/"]
    destination = "C:/Windows/Temp/scripts/"
  }
  provisioner "file" {
    sources     = ["build/"]
    destination = "C:/config"
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
    inline = ["C:/Windows/Temp/scripts/msibuilder.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/python.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/pip.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/pwsh.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/vsbuildtools.ps1"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/build-deps-unified.ps1 -configfiles C:\\config -workdir C:\\buildbot\\msbuild -openvpn_build_ref release/2.6 -debug"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/aws-cloudhsm.ps1 -configfiles C:\\config -workdir C:\\buildbot\\msbuild"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/jsign.ps1 -configfiles C:\\config -workdir C:\\buildbot\\msbuild"]
  }
}
