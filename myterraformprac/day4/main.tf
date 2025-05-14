provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "dineshpalli" {
  instance_type = "t2.micro"
  ami = "ami-03c3ac54a88879408"
  subnet_id = "subnet-0ab94ad8d00af9ea9"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "dp-terraform-practice"
}

resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-lock"
    Environment = "dev"
  }
}