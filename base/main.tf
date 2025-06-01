terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}
provider "aws" {
  region = var.aws_region
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "Terraform"
  default_tags {
    tags = {
      "Project" = "CloudX"
    }
  }
}