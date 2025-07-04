# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.4"
}
provider "aws" {
  region  = "eu-west-1"
  profile = "libertypisces"
}

