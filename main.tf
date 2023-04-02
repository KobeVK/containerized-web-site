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
  # region        = var.region

  # lifecycle {
  #  prevent_destroy = true
  # }
}

# resource "aws_instance" "web_app" {
#   ami           = "ami-0a89a7563fc68be84"
#   instance_type = "t2.micro"
#   key_name      = "mac_23"
#   vpc_security_group_ids =  ["sg-0fdca7d4d5179465b"]


# }

output "web_app_access_ip" {  
  value = aws_instance.web_app.public_ip
}

