terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }

  required_version = ">= 1.0"
}
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "Project" = "CloudX"
    }
  }
}