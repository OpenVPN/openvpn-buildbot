build {
  source "amazon-ebs.windows-server-2019" {
    name     = "msibuild-windows-server-2019-2.5"
    ami_name = "msibuild-windows-server-2019-2.5-1"
  }
  source "amazon-ebs.windows-server-2022" {
    name     = "msibuild-windows-server-2022-2.6"
    ami_name = "msibuild-windows-server-2022-2.6-1"
  }

  provisioner "file" {
    sources      = [ "../../scripts/" ]
    destination  = "C:/Windows/Temp/scripts/"
  }
  provisioner "file" {
    sources      = [ "build/" ]
    destination  = "C:/config"
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/base.ps1"]
  }
  provisioner "powershell" {
    elevated_password = var.windows_server_winrm_password
    elevated_user     = local.user_name
    inline = ["C:/Windows/Temp/scripts/openssh.ps1 -configfiles C:\\config"]
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
    only   = ["amazon-ebs.msibuild-windows-server-2019-2.5"]
    inline = ["C:/Windows/Temp/scripts/vsbuildtools.ps1 -version 2019"]
  }
  provisioner "powershell" {
    only   = ["amazon-ebs.msibuild-windows-server-2022-2.6"]
    inline = ["C:/Windows/Temp/scripts/vsbuildtools.ps1 -version 2022"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/vcpkg.ps1 -workdir C:\\buildbot\\msbuild"]
  }
  provisioner "powershell" {
    only   = ["amazon-ebs.msibuild-windows-server-2019-2.5"]
    inline = ["C:/Windows/Temp/scripts/build-deps.ps1 -workdir C:\\buildbot\\msbuild -openvpn_ref release/2.5 -openvpn_build_ref release/2.5 -openvpn_gui master -openssl openssl -debug"]
  }
  provisioner "powershell" {
    only   = ["amazon-ebs.msibuild-windows-server-2022-2.6"]
    inline = ["C:/Windows/Temp/scripts/build-deps.ps1 -workdir C:\\buildbot\\msbuild -openvpn_ref master -openvpn_build_ref master -openvpn_gui master -debug"]
  }
  provisioner "powershell" {
    inline = ["C:/Windows/Temp/scripts/aws-cloudhsm.ps1 -configfiles C:\\config -workdir C:\\buildbot\\msbuild"]
  }
}
