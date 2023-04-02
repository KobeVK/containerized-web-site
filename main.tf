variable "ami" {
  description = "The ID of the AMI to use for the instance"
}
variable "region" {
  description = "The ID of the AMI to use for the instance"
}
variable "type" {
  description = "The ID of the AMI to use for the instance"
}

provider "aws" {
  region     = var.region
}

resource "aws_instance" "web_app" {
  ami           = var.ami
  instance_type = var.type
}

# }

output "web_app_access_ip" {  
  value = aws_instance.web_app.public_ip
}

resource "local_file" "inventory" {
  content = <<-EOT
    [myhosts]
    ${aws_instance.web_app.public_ip} ansible_user=jenkins ansible_ssh_private_key_file=~/.ssh/mac_23.pem
  EOT

  filename = "/etc/ansible/hosts"
}