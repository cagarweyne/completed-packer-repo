variable "region" {
  type    = string
  description = "The region where the AMI will be made available"
  default = "us-east-2"
}

variable "docker_username" {
  type = string
  description = "The Docker username"
}

variable "docker_password" {
  type = string
  description = "The Docker password"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "nomad" {
  ami_name      = "nomad-ec2-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*" 
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["679593333241"]
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.nomad"]

  provisioner "file" {
    source      = "./tf-packer.pub"
    destination = "/tmp/tf-packer.pub"
  }
  
  provisioner "shell" {
    environment_vars = [
    "USERNAME=${var.docker_username}",
    "PASSWORD=${var.docker_password}"
  ]
    script = "./setup.sh"
  }

  provisioner "file" {
    source      = "./daemon.json"
    destination = "/tmp/daemon.json"
  }

  provisioner "shell" {
    script = "./move-daemon.sh"
  }
}

