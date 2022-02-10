# -------------------------------------------------------------
# Providers
# -------------------------------------------------------------

provider "aws" {
  region = local.region[terraform.workspace]
}

# -------------------------------------------------------------
# Backend
# ## For a better result we should use S3 bucket with MongoDB locking
# ## To save some money we will do it locally
# -------------------------------------------------------------

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}
