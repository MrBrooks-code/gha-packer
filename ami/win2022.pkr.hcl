packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

# Optional: if you want to lock down WinRM ingress to your runner egress IP later.
# For now, simplest is to let Packer manage a temporary SG.
# variable "winrm_allowed_cidr" { type = string default = "0.0.0.0/0" }

source "amazon-ebs" "win2022" {
  region        = var.region
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  instance_type = "t3.medium"

  # Latest official Windows Server 2022 Base AMI
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  communicator   = "winrm"
  winrm_username = "Administrator"

  # Packer will use HTTP WinRM (5985) in many examples.
  # This is OK for a short-lived build box inside your VPC when using the temporary SG.
  winrm_insecure = true
  winrm_timeout  = "45m"

  # Make it obvious this is a packer-built artifact
  ami_name        = "win2022-hello-{{timestamp}}"
  ami_description = "Windows Server 2022 AMI built by Packer (hello world demo)"

  run_tags = {
    Name = "packer-win2022"
  }

  tags = {
    Tool        = "Packer"
    Environment = "dev"
  }
}

build {
  sources = ["source.amazon-ebs.win2022"]

  provisioner "powershell" {
    inline = [
      "Write-Host 'Hello world from Packer on Windows Server 2022!'",
      "New-Item -ItemType Directory -Force -Path C:\\Temp | Out-Null",
      "Set-Content -Path C:\\Temp\\hello.txt -Value 'Hello world baked into AMI'",
      "Get-Content C:\\Temp\\hello.txt"
    ]
  }

  # Optional, but recommended to make first-boot experience clean:
  # provisioner "powershell" {
  #   inline = [
  #     "& 'C:\\Program Files\\Amazon\\EC2Launch\\ec2launch.exe' reset --sysprep"
  #   ]
  # }
}
