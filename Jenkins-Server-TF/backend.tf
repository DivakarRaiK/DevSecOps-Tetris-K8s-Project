terraform {
  backend "s3" {
    bucket       = "devops-tf-bucket-divakar"
    region       = "us-east-1"
    key          = "DevSecOps-Tetris-K8s-Project/Jenkins-Server-TF/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
  required_version = ">=1.13.3"
  required_providers {
    aws = {
      version = ">= 6.23.0"
      source  = "hashicorp/aws"
    }
  }
}