# status backend from terraform in terraform.io
# Backend
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "BextEx_Research"
    workspaces {
      prefix = "ber-logging-"
    }
  }

  required_version = ">= 1.2.2"
}