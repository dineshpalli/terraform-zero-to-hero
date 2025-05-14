variable "VAULT_ROLE_ID" {
  description = "Vault AppRole Role ID"
  type        = string
}

variable "VAULT_SECRET_ID" {
  description = "Vault AppRole Secret ID"
  type        = string
}

provider "aws" {
  region = "ap-south-1"
}

provider "vault" {
  address = var.vault_addr
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id = var.vault_role_id
      secret_id = var.vault_secret_id
    }
  }
}

variable "vault_addr" {}
variable "vault_role_id" {}
variable "vault_secret_id" {}

data "vault_kv_secret_v2" "example" {
  mount = "secret"
  name  = "test-secret"
}

resource "aws_instance" "my_instance" {
  ami           = "ami-0e35ddab05955cf57"
  instance_type = "t2.micro"

  tags = {
    Name = "test"
    Secret = data.vault_kv_secret_v2.example.data["foo"]
  }
}