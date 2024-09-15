terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.41.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "null_resource" "example" {
    triggers = {
    value = "A example resource that does nothing!"
    }
}