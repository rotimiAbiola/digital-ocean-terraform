terraform {
  cloud {
    organization = "rtm-demo-lab"

    workspaces {
      name = "digital-ocean-terraform"
    }
  }
}