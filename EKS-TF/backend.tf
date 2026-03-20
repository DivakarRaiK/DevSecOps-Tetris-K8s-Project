terraform {
  backend "s3" {
    bucket       = "devops-tf-bucket-divaka"
    region       = "us-east-1"
    key          = "DevSecOps-Tetris-K8s-Project/EKS-TF/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_version = ">=1.14.0"
  required_providers {
    aws = {
      version = ">= 5.49.0"
      source  = "hashicorp/aws"
    }
  }
}