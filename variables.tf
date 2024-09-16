variable "region" {
  default = "nyc3"
  description = "Region where resources will be provisioned"
  type = string
}

variable "db_size" {
  default = "db-s-1vcpu-1gb"
  description = "Size of the database"
  type = string
}

variable "droplet_size" {
  default = "s-1vcpu-1gb"
  description = "Size of the droplet"
  type = string
}

variable "image" {
  default = "ubuntu-20-04-x64"
  description = "Image for the droplets"
  type = string
}

variable "ssh_key_name" {
  description = "ssh public key for the droplets"
  type = string
}

variable "domain" {
  description = "domain name"
  type = string
}
