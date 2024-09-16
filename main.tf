# VPC
resource "digitalocean_vpc" "network" {
  name     = "mydo_network"
  region   = var.region
  ip_range = "10.10.1.0/24"
}

# Database
resource "digitalocean_database_cluster" "db-cluster" {
  name       = "mypostgres-cluster"
  engine     = "pg"
  version    = "16"
  size       = var.db_size
  region     = var.region
  node_count = 1
  private_network_uuid = digitalocean_vpc.network.id
}

# Database Firewall
resource "digitalocean_database_firewall" "db-fw" {
  cluster_id = digitalocean_database_cluster.db-cluster.id

  rule {
    type  = "tag"
    value = digitalocean_tag.droplet_tag.id
  }
}

# SSH Keys
resource "digitalocean_ssh_key" "ssh_pub_keys" {
  name = "Terraforn pubkey"
  public_key = var.ssh_key_name
}

resource "digitalocean_tag" "droplet_tag" {
  name = "app-servers"
}

# Droplets
resource "digitalocean_droplet" "web" {
  image  = var.image
  count = 3
  name   = "web-${count.index}"
  region = var.region
  size   = var.droplet_size
  ssh_keys = [
    digitalocean_ssh_key.ssh_pub_keys.id
  ]
  monitoring = true
  vpc_uuid = digitalocean_vpc.network.id
  tags   = [digitalocean_tag.droplet_tag.id]
  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Welcome to $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
              EOF
}

# Droplet Firewall
resource "digitalocean_firewall" "droplet-fw" {
    name = "app-droplet-fw"
    droplet_ids = [digitalocean_droplet.web.*.id]

    inbound_rule {
        protocol         = "tcp"
        port_range       = "80"
        source_load_balancer_uids = [digitalocean_loadbalancer.public.id]
    }

    inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
    }

    inbound_rule {
        protocol         = "icmp"
        source_addresses = ["0.0.0.0/0", "::/0"]
    }

    outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
}

outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
}

outbound_rule {
    protocol              = "icmp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
}
}

resource "digitalocean_domain" "default" {
  name       = var.domain
  ip_address = digitalocean_loadbalancer.public.id
}

# cert
resource "digitalocean_certificate" "cert" {
  name    = "web cert"
  type    = "lets_encrypt"
  domains = [ var.domain ]
}

# Loadbalancer
resource "digitalocean_loadbalancer" "public" {
  name   = "mylb"
  region = var.region
  vpc_uuid = digitalocean_vpc.network.id
  droplet_tag = "app-servers"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_name = digitalocean_certificate.cert.id
  }

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"

    certificate_name = digitalocean_certificate.cert.id
  }
  healthcheck {
    port     = 22
    protocol = "tcp"
    path = "/"
  }

  droplet_ids = [digitalocean_droplet.web.*.id]

  redirect_http_to_https = true

  firewall {
    
  }

}
