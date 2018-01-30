/*
 * PromGuard Terraform
 * @cpu - 2018
 *
 * An example of creating 1 monitoring node, and n target nodes. Target nodes
 * are spread across geographically diverse regions. Template datasources are
 * used to populate an Ansible inventory output. Later Ansible playbooks will
 * create an encrypted site-to-site tunnel between the monitoring node and the
 * target nodes.
 *
 */

/*
 * Placeholder variables - populate these in your `terraform.tfvars` file.
 */
variable "do_token" {}
variable "do_ssh_key_file" {}
variable "do_ssh_key_name" {
  default = "promguard-ssh"
}

/*
 * PromGuard Configuration Options
 */

# What size of Droplet should be used?
variable "do_size" {
  default = "1gb"
}

# What droplet image should be used?
variable "do_image" {
  default = "ubuntu-16-04-x64"
}

# What region should the monitoring droplet be in?
# Default: Toronto, CA
variable "do_monitor_region" {
  default = "tor1"
}

# How many nodes should be created - make sure `do_node_regions` has an entry
# for each `node_count` if you change this!
variable "node_count" {
  default = 3
}

# What regions should each of the remote nodes be created in?
# Default:
#  Node 1 - London, UK
#  Node 2 - San Franciso, US
#  Node 3 - Singapore, SG
variable "do_node_regions" {
  type = "map"

  default = {
    "promguard-node-1" = "lon1"
    "promguard-node-2" = "sfo2"
    "promguard-node-3" = "sgp1"
  }
}

/*
 * Terraform outputs
 */

# ansible_inventory is an output for the rendered ansible_inventory template
output "ansible_inventory" {
  value = "${data.template_file.ansible_inventory.rendered}"
}

# monitor_ip is an output for the public IPv4 address of the monitor droplet
# used for SSH port forwarding
output "monitor_ip" {
  value = "${digitalocean_droplet.monitor.ipv4_address}"
}

/*
 * Template Data Sources
 */

# nodes_ansible is a template datasource that constructs a hostname template for
# each of the "node" droplets
data "template_file" "nodes_ansible" {
  count = "${var.node_count}"
  template = "${file("${path.module}/templates/hostname.tpl")}"
  vars {
    name = "promguard-node-${count.index + 1}"
    ansible_host = "ansible_host=${digitalocean_droplet.node.*.ipv4_address[count.index]}"
    # Each monitor host is given a sequential address in the RFC 1918 10.0.0.0
    # network using the `cidrhost` function. The node offset is the index
    # + 2 - this accounts for both zero offset indexing as well as for the
    # monitor host
    wireguard_ip = "wireguard_ip=${cidrhost("10.0.0.0/24", count.index + 2)}"
  }
}

# monitor_ansible is a template datasource that constructs a hostname template
# only for the "monitor" droplet
data "template_file" "monitor_ansible" {
  template = "${file("${path.module}/templates/hostname.tpl")}"
  vars {
    name = "promguard-monitor-1"
    ansible_host = "ansible_host=${digitalocean_droplet.monitor.ipv4_address}"
    # The monitor wireguard_ip is always the first host in the 10.0.0.0 subnet
    # for this example code.
    wireguard_ip = "wireguard_ip=${cidrhost("10.0.0.0/24", 1)}"
  }
}

# ansible_inventory is a template datasource that stitches together the
# nodes_ansible and monitor_ansible datasources to make an Ansible inventory
data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/templates/inventory.tpl")}"
  vars {
    monitor = "${data.template_file.monitor_ansible.rendered}"
    node_hosts = "${join("",data.template_file.nodes_ansible.*.rendered)}"
  }
}


/*
 * DigitalOcean provider & resources
 */

# Use DigitalOcean as the provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Create an SSH key for the PromGuard droplets to reference
resource "digitalocean_ssh_key" "promguard-ssh" {
  name = "${var.do_ssh_key_name}"
  public_key = "${file(var.do_ssh_key_file)}"
}

# Create an overall "promguard" tag that all droplets will reference
resource "digitalocean_tag" "promguard" {
  name = "promguard"
}

# Create a "promguard_monitor" tag that only the monitor host will reference
resource "digitalocean_tag" "promguard_monitor" {
  name = "promguard_monitor"
}

# Create a "promguard_node" tag that only the to-be-monitored nodes will
# reference
resource "digitalocean_tag" "promguard_node" {
  name = "promguard_node"
}

# Create a single "monitor" droplet in the do_monitor_region
# A "remote-exec" provisioner is used to ensure SSH access is available and
# Python installed before continuing with further provisioning stages.
resource "digitalocean_droplet" "monitor" {
  name = "promguard-monitor-1"
  region = "${var.do_monitor_region}"
  image = "${var.do_image}"
  size = "${var.do_size}"
  ssh_keys = [ "${digitalocean_ssh_key.promguard-ssh.id}" ]
  tags = [ "${digitalocean_tag.promguard.id}", "${digitalocean_tag.promguard_monitor.id}" ]

  provisioner "remote-exec" {
    inline = [
      "# Connected!",
      "apt update",
      "apt install -y python"
    ]
  }
}

# Create node_count separate to-be-monitored nodes, each in a unique region
# based on the do_node_regions map.
# A "remote-exec" provisioner is used to ensure SSH access is available and
# Python installed before continuing with further provisioning stages.
resource "digitalocean_droplet" "node" {
  count = "${var.node_count}"
  name = "promguard-node-${count.index + 1}"
  region = "${var.do_node_regions["promguard-node-${count.index +1 }"]}"
  image = "${var.do_image}"
  size = "${var.do_size}"
  ssh_keys = [ "${digitalocean_ssh_key.promguard-ssh.id}" ]
  tags = [ "${digitalocean_tag.promguard.id}", "${digitalocean_tag.promguard_node.id}" ]
  depends_on = [ "digitalocean_droplet.monitor" ]

  provisioner "remote-exec" {
    inline = [
      "# Connected!",
      "apt update",
      "apt install -y python"
    ]
  }
}
