
variable "environment" {}
variable "id" {}
variable "aws_region" {
  default = "eu-west-3"
}

provider "aws" {
  region     = var.aws_region
}

resource "aws_instance" "web_app" {
  ami           = "ami-0a89a7563fc68be84"
  instance_type = "t2.micro"
  key_name      = "mac_23"
  vpc_security_group_ids =  ["sg-0fdca7d4d5179465b"]

  # lifecycle {
  #  prevent_destroy = true
  # }
}


output "web_app_access_ip" {  
  value = aws_instance.web_app.public_ip
}

