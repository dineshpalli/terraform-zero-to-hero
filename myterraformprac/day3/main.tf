provider "aws" {
  region = "ap-south-1"
}

module "ec2_instance" {
  source = "./modules/ec2_instance"
  ami_value = "ami-03c3ac54a88879408"
  instance_type_value = "t2.micro"
  subnet_id_value = "subnet-0ab94ad8d00af9ea9"
}