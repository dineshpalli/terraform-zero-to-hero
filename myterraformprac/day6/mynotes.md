1. Terraform workspaces (the official feature)

Key point	What it means
What it is	A built‑in Terraform CLI concept that lets a single configuration keep multiple, isolated state files in the same backend.
How it works	Every backend key is automatically namespaced by the workspace name (<workspace>/terraform.tfstate for most back‑ends).
Default	You always start in the workspace called default.
Typical use	Keeping dev / staging / prod (or per‑branch, per‑tenant, etc.) states without copying the code.
CLI commands	terraform workspace list, terraform workspace new dev, terraform workspace select prod, etc.
Remote back‑ends	The workspace name is injected into the back‑end key; no manual path juggling needed.
Variables	You can load workspace‑specific .tfvars files with a naming convention (terraform.tfvars, dev.tfvars, etc.) or by using -var-file.
State isolation	Hard isolation – one state file per workspace, so resources cannot accidentally overlap.

Minimal example

# still in the same code directory
terraform workspace new dev
terraform apply -var-file=dev.tfvars     # creates dev resources

terraform workspace new prod
terraform apply -var-file=prod.tfvars    # creates prod resources

# Switching back and forth
terraform workspace select dev
terraform output


⸻

2. “Environments” (a workflow pattern, not a first‑class feature)

Terraform itself doesn’t have an environment primitive, but teams still talk about “environments” in three common ways:

Pattern	How it’s usually done	Pros & cons (in a nutshell)
Directory‑per‑environment	live/dev/, live/staging/, live/prod/ each containing their own .tf files and their own back‑end blocks.	Simple mental model, but you duplicate code and must keep the directories in sync.
Module‑per‑environment repo	Separate Git repos or branches (myservice‑dev‑infra, myservice‑prod‑infra).	Clean separation and ACLs, but even more duplication.
Terraform Cloud/Enterprise “workspaces as environments”	In TFC/TFE you create one workspace per environment; each run gets its own variable set and run queue.	Usually the smoothest option in TFC/TFE; still not called “environment” by Terraform, but the UI can label them as such.

Minimal directory‑based example

repo-root
└── live
    ├── dev
    │   ├── backend.tf     # points at dev state path
    │   └── main.tf
    └── prod
        ├── backend.tf     # points at prod state path
        └── main.tf

You would run:

cd live/dev   && terraform init && terraform apply   # dev
cd ../prod    && terraform init && terraform apply   # prod


⸻

3. Head‑to‑head comparison

Feature / concern	Terraform workspace	“Environment” (directory/repo/TFC label)
First‑class in CLI?	✅ Yes	❌ No
State isolation	Automatic: one state file per workspace	You create a separate back‑end key or even back‑end block manually
Code duplication	None – same code directory	Usually duplicates root modules or entire repos
Switching context	terraform workspace select <name>	cd into another dir or checkout another branch
Variable segregation	Via *.tfvars or TFC variable sets keyed to workspace	Via different files / directories / repos
Risk of resource name collision	Low (namespaced by state)	Depends on your naming / variable discipline
Good for	Many small, nearly identical stacks (per‑PR, per‑tenant)	Stacks that genuinely diverge over time, or need separate repos & pipelines
Limitation	One workspace is active in your working directory at a time; no parallel applies from same dir	More setup & maintenance effort; harder to DRY the code


⸻

4. Which should I use?
	•	Start with workspaces when the only difference between “dev”, “qa”, and “prod” is inputs (region, size, count, tags, etc.).
	•	Switch to separated environments when:
	•	You need distinct pipelines, permissions, or repo history.
	•	The configurations will drift apart and require different resources.
	•	Teams manage their environments on different cadences.

Many real‑world setups are hybrids:
One Git repo ➜ “live” folder ➜ one directory per major environment ➜ inside each directory, multiple workspaces for ephemeral feature branches.

⸻

TL;DR
	•	Workspaces = baked‑in, lightweight, state isolation.
	•	Environments = a naming convention / repo layout or a Terraform Cloud idiom you create yourself.
Pick the one whose operational overhead and safety boundaries match your team’s needs best.

Below is a “from zero‑to‑hero” walkthrough that ties the concepts together, shows the exact CLI commands you’ll type, and explains why each step matters.

⸻

1. How workspaces isolate configurations

What actually happens under the hood 🔍

Terraform keeps one state file per workspace in the same backend.
For most back‑ends, the workspace’s name is prepended to the state‑file key:

Backend key template      →   <workspace>/terraform.tfstate
Example (S3 backend)      →   s3://my‑bucket/dev/terraform.tfstate

Because the state is what maps real cloud resources to your .tf code, placing it in different keys guarantees that:

1. Resources created in workspace A are invisible to workspace B.
2. You can reuse exactly the same code without risk of name collisions—unless you hard‑code duplicate cloud‑side names yourself.

⸻

Micro‑example: one S3 bucket, two environments

# main.tf
resource "aws_s3_bucket" "app" {
  bucket = "myapp-${terraform.workspace}-bucket"
}

	•	Workspace dev produces → myapp-dev-bucket
	•	Workspace prod produces → myapp-prod-bucket

Even though the resource block is identical, the bucket names (and state files) are isolated.

⸻

2. Creating and switching between workspaces 🛠️

All commands are run inside the root of the same Terraform configuration.

Action	Command	What it does
List existing workspaces	terraform workspace list	Shows * default and any others you created
Create a workspace	terraform workspace new dev	Initializes an empty state named dev
Switch to a workspace	terraform workspace select dev	Future plan/apply runs use dev state
Rename (v1.6+)	terraform workspace rename dev development	Handy for typo fixes
Delete	terraform workspace delete dev	Removes only the workspace’s state, not cloud resources

Hands‑on sequence

# 1. Init in default workspace (state path: default/terraform.tfstate)
terraform init

# 2. Carve off a dev environment
terraform workspace new dev
terraform plan            # now runs against dev state
terraform apply           # provisions dev resources

# 3. Spin up prod next
terraform workspace new prod
terraform apply -var-file=prod.tfvars

# 4. Jump back and forth as needed
terraform workspace select dev
terraform output


⸻

3. Using workspaces for environment management 🏗️

A minimalist pattern (dev / qa / prod)

repo‑root
│   main.tf
│   variables.tf
├── dev.tfvars   # cheap instance sizes, dummy e‑mail sender
├── qa.tfvars    # scale‑down but real integrations
└── prod.tfvars  # full replica, real domains & secrets via TF Cloud

Run flow:

terraform workspace new dev
terraform apply  -var-file=dev.tfvars

terraform workspace new qa
terraform apply  -var-file=qa.tfvars

terraform workspace new prod
terraform apply  -var-file=prod.tfvars

The same commit hash is now running three separate copies of your stack, each mapped to its own state file and set of inputs.

⸻

Auto‑loading vars with naming convention

If you name the files <workspace>.auto.tfvars, Terraform picks the right file automatically:

dev.auto.tfvars
qa.auto.tfvars
prod.auto.tfvars

No need for -var-file; the correct vars are loaded based on terraform.workspace.

⸻

Dynamic behavior inside .tf files

You can branch on the active workspace:

locals {
  enable_cost_saver = terraform.workspace != "prod"
}

resource "aws_autoscaling_schedule" "nightly_scale_down" {
  count  = local.enable_cost_saver ? 1 : 0
  # ...
}

	•	In dev/qa the schedule exists and saves money.
	•	In prod it’s omitted entirely.

⸻

4. Benefits and caveats ⚖️

✔️ Strengths	⚠️ Watch‑outs
Zero code duplication—just swap workspaces	Only one workspace can be active per working directory; concurrent automation needs separate clones or TFC/TFE
Back‑end namespacing handled for you	Resource names must still include the workspace in your naming scheme (e.g., bucket names) to avoid cloud‑side conflicts
Works locally, in CI, and in Terraform Cloud/Enterprise	Not ideal once environments diverge (different providers, modules, or major topologies)


⸻

5. When to choose workspaces vs. separate directories/repos

Use workspaces when:
	•	The environments differ only in inputs (size, region, count, secrets).
	•	You want fast spins of short‑lived stacks (per‑PR, per‑tenant).

Switch to directory‑or‑repo separation when:
	•	The infrastructure shape will drift apart over time.
	•	You need different pipelines, IAM policies, or provider versions per environment.

⸻

TL;DR

Workspaces are Terraform’s built‑in isolation lever.
They slice the state file per environment so you can run dev → QA → prod from the same code base with just a terraform workspace select. Keep your variable hygiene clean, watch the resource‑name patterns, and you unlock safe, low‑overhead environment management.

# From Reddit:

(workspaces just change where your terraform state goes and are compatible with DRY terraform.)[https://www.reddit.com/r/devops/comments/x4qlg5/comment/imx1nq8/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button]
I started with using folders (which was Hashi's best practice), but the real challenge is that it's super super hard to make sure your infra change makes it everywhere and is deployed consistently. Folders containing root modules end up getting mixed up with reusable modules and that's a pain in the ass to train your traditional operators on.

The DRY terraform methodologies, either through terragrunt or structured .tfvars files, is far more consistent and easier to manage. Setting up folders is a fool's errand, because you'll be chasing down every folder to repeat the same update for N environments, where that's only the case for tfvars if it's actually a variable cahnging.

