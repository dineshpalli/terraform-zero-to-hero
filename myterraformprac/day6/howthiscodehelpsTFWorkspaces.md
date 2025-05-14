The Terraform setup is using workspaces and a terraform.tfvars file to dynamically choose configurations, specifically the EC2 instance type, based on the current workspace.

Here’s how it all ties together:

⸻

✅ main.tf (root level)

Contains:

variable "instance_type" {
  type = map(string)
  default = {
    "dev"   = "t2.micro"
    "stage" = "t2.medium"
    "prod"  = "t2.xlarge"
  }
}

module "ec2_instance" {
  source         = "./modules/ec2_instance"
  ami            = var.ami
  instance_type  = lookup(var.instance_type, terraform.workspace, "t2.micro")
}

	•	It uses terraform.workspace to dynamically select the instance type.
	•	This means when you run terraform workspace select prod, it will pick t2.xlarge.

⸻

✅ terraform.tfvars

Contains:

ami = "ami-03c3ac54a88879408"

	•	This supplies the AMI ID as a variable value to your module.
	•	Be careful: the AMI ID must exist in your current region (ap-south-1), otherwise you’ll get the InvalidAMIID.NotFound error.

⸻

✅ modules/ec2_instance/main.tf

Contains the actual EC2 instance resource using the passed-in ami and instance_type.

⸻

🔁 Relationship with Workspace

Terraform uses:

lookup(var.instance_type, terraform.workspace, "t2.micro")

to map:
	•	"dev" → "t2.micro"
	•	"stage" → "t2.medium"
	•	"prod" → "t2.xlarge"

This allows us to run the same codebase across environments like this:

terraform workspace select stage
terraform apply

and it will automatically use t2.medium.

⸻