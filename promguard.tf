variable "do_token" {}

variable "do_ssh_key_file" {}

variable "do_ssh_key_name" {
  default = "promguard ssh key"
}

variable "node_count" {
  default = 3
}

variable "do_size" {
  default = "1gb"
}

variable "do_image" {
  default = "ubuntu-16-04-x64"
}

variable "do_monitor_region" {
  default = "tor1"
}

variable "do_node_regions" {
  type = "map"

  default = {
    "promguard-node-1" = "lon1"
    "promguard-node-2" = "sfo2"
    "promguard-node-3" = "sgp1"
  }
}

data "template_file" "nodes_ansible" {
  count = "${var.node_count}"
  template = "${file("${path.module}/templates/hostname.tpl")}"
  vars {
    name = "promguard-node-${count.index + 1}"
    ansible_host = "ansible_host=${digitalocean_droplet.node.*.ipv4_address[count.index]}"
    wireguard_ip = "wireguard_ip=${cidrhost("10.0.0.0/24", count.index + 2)}"
  }
}

data "template_file" "monitor_ansible" {
  template = "${file("${path.module}/templates/hostname.tpl")}"
  vars {
    name = "promguard-monitor-1"
    ansible_host = "ansible_host=${digitalocean_droplet.monitor.ipv4_address}"
    wireguard_ip = "wireguard_ip=${cidrhost("10.0.0.0/24", 1)}"
  }
}

data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/templates/inventory.tpl")}"
  vars {
    monitor = "${data.template_file.monitor_ansible.rendered}"
    node_hosts = "${join("",data.template_file.nodes_ansible.*.rendered)}"
  }
}

output "ansible_inventory" {
  value = "${data.template_file.ansible_inventory.rendered}"
}

output "monitor_ip" {
  value = "${digitalocean_droplet.monitor.ipv4_address}"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "promguard-ssh" {
  name = "${var.do_ssh_key_name}"
  public_key = "${file(var.do_ssh_key_file)}"
}

resource "digitalocean_tag" "promguard" {
  name = "promguard"
}

resource "digitalocean_tag" "promguard_monitor" {
  name = "promguard_monitor"
}

resource "digitalocean_tag" "promguard_node" {
  name = "promguard_node"
}

resource "digitalocean_droplet" "monitor" {
  image = "${var.do_image}"
  name = "promguard-monitor-1"
  region = "${var.do_monitor_region}"
  size = "${var.do_size}"
  ssh_keys = [ "${digitalocean_ssh_key.promguard-ssh.id}" ]
  tags = [ "${digitalocean_tag.promguard.id}", "${digitalocean_tag.promguard_monitor.id}" ]

  provisioner "remote-exec" {
    inline = [ "# Connected!"]
  }
}

resource "digitalocean_droplet" "node" {
  count = "${var.node_count}"
  image = "${var.do_image}"
  name = "promguard-node-${count.index + 1}"
  region = "${var.do_node_regions["promguard-node-${count.index +1 }"]}"
  size = "${var.do_size}"
  ssh_keys = [ "${digitalocean_ssh_key.promguard-ssh.id}" ]
  tags = [ "${digitalocean_tag.promguard.id}", "${digitalocean_tag.promguard_node.id}" ]
  depends_on = [ "digitalocean_droplet.monitor" ]

  provisioner "remote-exec" {
    inline = [ "# Connected!"]
  }
}
