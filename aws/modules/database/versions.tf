terraform {
  required_version = ">= 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7"
    }
  }
}
