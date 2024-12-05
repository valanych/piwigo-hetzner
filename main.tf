# Tell Terraform to include the hcloud provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.47.0"
    }
  }
}

# Declare the hcloud_token variable from .tfvars
variable "hcloud_token" {
  sensitive = true
}
variable "server_type" {
  type = string
}
variable "server_location" {
  type = string
}
variable "master_private_key" {
  sensitive = true
}
variable "master_public_key" {
  sensitive = true
}
variable "DOCKERHUB_USERNAME" {
  sensitive = true
}
variable "DOCKERHUB_PASSWORD" {
  sensitive = true
}
variable "mysql_password" {
  sensitive = true
}

# Configure the Hetzner Cloud Provider with your token
provider "hcloud" {
  token = var.hcloud_token
}

resource "random_id" "server_suffix" {
  byte_length = 2
}

resource "hcloud_server" "master-node" {
  name        = "master-node-${random_id.server_suffix.hex}"
  image       = "ubuntu-22.04"
  server_type = var.server_type
  location    = var.server_location
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    master_public_key = file("${path.module}/${var.master_public_key}"),
    init_server = file("${path.module}/init-server.sh"),
    compose_yaml = templatefile("${path.module}/docker-compose.yml", {
      mysql_passwd = var.mysql_password
    }),
    run_compose = templatefile("${path.module}/run-compose.sh", {
      DOCKERHUB_PASSWORD = var.DOCKERHUB_PASSWORD,
      DOCKERHUB_USERNAME = var.DOCKERHUB_USERNAME
    }),
    run_reboot = file("${path.module}/run-reboot.sh")
  })

  # If we don't specify this, Terraform will create the resources in parallel
  # We want this node to be created after the private network is created
  #depends_on = [hcloud_network_subnet.private_network_subnet]
}

resource "hcloud_volume" "master-volume" {
  name      = "master-volume-${random_id.server_suffix.hex}"
  size      = 10  
  server_id = hcloud_server.master-node.id
  automount = true
  format    = "ext4"
  delete_protection = false

  connection {
    type     = "ssh"
    user     = "piwigo"
    private_key = file("${path.module}/${var.master_private_key}")
    host     = hcloud_server.master-node.ipv4_address
    script_path = "/home/piwigo/remote-exec.sh"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo ln -s /mnt/HC_Volume_${self.id} /mnt/ext_volume",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/piwigo/config",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/piwigo/gallery",
      "sudo mkdir -p $(readlink -f /mnt/ext_volume)/mysql",
    ]
  }
}

resource "null_resource" "run_scripts" {
  connection {
    type     = "ssh"
    user     = "piwigo"
    private_key = file("${path.module}/${var.master_private_key}")
    host     = hcloud_server.master-node.ipv4_address
    script_path = "/home/piwigo/remote-exec.sh"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /root/init-server.sh 2>&1 | tee ~/init-server.log",
      "sudo /root/run-compose.sh -f /root/docker-compose.yml up -d --wait 2>&1 | tee ~/run-compose.log",
      "sudo /root/run-reboot.sh 2>&1 | tee ~/run-reboot.log"
    ]
  }

  depends_on = [hcloud_server.master-node, hcloud_volume.master-volume]
}

#resource "hcloud_volume_attachment" "testvolume_attachment" {
#  volume_id = hcloud_volume.master.id
#  server_id = hcloud_server.master-node.id
#  automount = true
#}
