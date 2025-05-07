packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  user_name = "Administrator"
}

variable "windows_server_buildbot_user_password" {
  type = string
}

variable "buildmaster_address" {
  description = "IP address or DNS name of buildmaster"
  type = string
}

variable "windows_server_buildbot_worker_password" {
  description = "Password for authenticating to buildmaster"
  type = string
}

variable "windows_server_ec2_region" {
  type = string
}

variable "windows_server_ec2_subnet" {
  type    = string
  default = null
}

variable "windows_server_instance_profile" {
  type    = string
  default = null
}

variable "windows_server_winrm_password" {
  type = string
}

variable "run_tags" {
  type = map(string)
  default = {
    Name = "openvpn-buildbot Packer build"
  }
}

source "amazon-ebs" "windows-server-2022" {
  communicator         = "winrm"
  force_deregister     = true
  instance_type        = "c6a.xlarge"
  iam_instance_profile = var.windows_server_instance_profile
  region               = var.windows_server_ec2_region
  subnet_id            = var.windows_server_ec2_subnet

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 80
    volume_type           = "gp3"
    delete_on_termination = true
  }

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["801119661308"]
  }
  user_data      = templatefile("${path.root}/../../pkrtpl/bootstrap_win.pkrtpl.hcl", { winrm_password = var.windows_server_winrm_password })
  winrm_password = var.windows_server_winrm_password
  winrm_username = "Administrator"

  tags = {
    SourceAMI     = "{{ .SourceAMI }}"
    SourceAMIName = "{{ .SourceAMIName }}"
    Login         = local.user_name
  }

  dynamic "run_tag" {
    for_each = var.run_tags

    content {
      key   = run_tag.key
      value = run_tag.value
    }
  }
}

source "amazon-ebs" "windows-server-2025" {
  communicator         = "winrm"
  force_deregister     = true
  instance_type        = "c6a.xlarge"
  iam_instance_profile = var.windows_server_instance_profile
  region               = var.windows_server_ec2_region
  subnet_id            = var.windows_server_ec2_subnet

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 80
    volume_type           = "gp3"
    delete_on_termination = true
  }

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2025-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["801119661308"]
  }
  user_data      = templatefile("${path.root}/../../pkrtpl/bootstrap_win.pkrtpl.hcl", { winrm_password = var.windows_server_winrm_password })
  winrm_password = var.windows_server_winrm_password
  winrm_username = "Administrator"

  tags = {
    SourceAMI     = "{{ .SourceAMI }}"
    SourceAMIName = "{{ .SourceAMIName }}"
    Login         = local.user_name
  }

  dynamic "run_tag" {
    for_each = var.run_tags

    content {
      key   = run_tag.key
      value = run_tag.value
    }
  }
}
