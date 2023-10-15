terraform {
  backend "s3" {
    bucket = "terraform-state-storage123"
    key    = "dev/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
}
