terraform {
  backend "remote" {
    hostname     = "stackweaver.vhco.pro"
    organization = "main"
    token = var.stackweaver_token
    workspaces {
      name = "tfe-tests"
    }
  }

  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "~> 0.72.0"
    }
  }
}