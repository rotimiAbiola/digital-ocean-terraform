terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.41.0"
    }
  }
}

provider "digitalocean" {
}