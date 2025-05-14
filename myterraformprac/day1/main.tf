provider "aws" {
    region = "ap-south-1"  # Set your desired AWS region
}

resource "aws_instance" "day1-webserver" {
    ami           = "ami-03c3ac54a88879408"  # Use the selected AMI ID
    instance_type = "t2.micro"
}