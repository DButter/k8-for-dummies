terraform {
  backend "s3" {
    bucket  = "davids-master-state-bucket"
    key     = "calico/terraform.tfstate"
    region  = "eu-central-1"
    profile = "saml"
  }
}

provider "aws" {
  profile = "saml"
  region  = "eu-central-1"
}
