terraform {
  backend "s3" {
    bucket         = "dp-terraform-practice" # change this
    key            = "dineshterraformpractice/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}