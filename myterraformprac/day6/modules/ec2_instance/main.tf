provider "aws" {
    region = "ap-south-1"
}

variable "ami" {
  description = "This is AMI for the instance"
  default     = "ami-03c3ac54a88879408"
}

variable "instance_type" {
  description = "This is the instance type, for example: t2.micro"
}

resource "aws_instance" "example" {
    ami = var.ami
    instance_type = var.instance_type
}