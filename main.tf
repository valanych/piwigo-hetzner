# Tell Terraform to include the hcloud provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      # Here we use version 1.45.0, this may change in the future
      version = "1.47.0"
    }
  }
}

# Declare the hcloud_token variable from .tfvars
variable "hcloud_token" {
  sensitive = true # Requires terraform >= 0.14
}
variable "hello" {
  sensitive = true # Requires terraform >= 0.14
}

variable "master_public_key" {
  sensitive = true
}
variable "master_private_key" {
  sensitive = true
}
variable "worker_public_key" {
  sensitive = true
}
variable "worker_private_key" {
  sensitive = true
}
variable "DOCKERHUB_USERNAME" {
  sensitive = true
}
variable "DOCKERHUB_PASSWORD" {
  sensitive = true
}

# Configure the Hetzner Cloud Provider with your token
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "master-node" {
  name        = "master-node"
  image       = "ubuntu-22.04"
  server_type = "cax11"
  location    = "fsn1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    master_public_key = file("${path.module}/.mysecrets/id_rsa.hetzner.pub"),
    init_server = file("${path.module}/init-server.sh"),
    compose_yaml = templatefile("${path.module}/docker-compose.yml", {
      mysql_passwd = "example"
    }),
    run_compose = templatefile("${path.module}/run-compose.sh", {
      DOCKERHUB_PASSWORD = var.DOCKERHUB_PASSWORD,
      DOCKERHUB_USERNAME = var.DOCKERHUB_USERNAME
    })
  })

  # If we don't specify this, Terraform will create the resources in parallel
  # We want this node to be created after the private network is created
  #depends_on = [hcloud_network_subnet.private_network_subnet]
}

resource "hcloud_volume" "master" {
  name      = "ext-volume"
  size      = 10  
  server_id = hcloud_server.master-node.id
  automount = true
  format    = "ext4"
  delete_protection = false

  connection {
    type     = "ssh"
    user     = "cluster"
    private_key = file("${path.module}/.mysecrets/id_rsa.hetzner")
    host     = hcloud_server.master-node.ipv4_address
    script_path = "/home/cluster/remote-exec.sh"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ln -s /mnt/HC_Volume_${self.id} /mnt/ext_volume",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/piwigo/config",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/piwigo/gallery",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/mysql",
      "sudo /root/init-server.sh",
      "sudo /root/run-compose.sh -f /root/docker-compose.yml up -d"
    ]
  }
}

#resource "hcloud_volume_attachment" "testvolume_attachment" {
#  volume_id = hcloud_volume.master.id
#  server_id = hcloud_server.master-node.id
#  automount = true
#}
