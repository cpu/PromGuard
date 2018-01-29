#!/bin/bash

set -e

source "util/ansible-check.sh"
source "util/terraform-check.sh"
source "util/quit.sh"

# Ensure ansible is installed
check_ansible
# Ensure terraform is installed
check_terraform
# Ensure the terraform.tfvars file with secret vars exists
notexists_quit "./terraform.tfvars" "Create terraform.tfvars, see README.md"

# Apply changes as required
terraform apply
# Output an Ansible inventory
terraform output ansible_inventory > inventory

# Configure everything with Ansible
ansible-playbook playbooks/promguard.yml

# All done!
echo "All finished! WooHoo!"
echo "You can now access prometheus through a SSH port forward to the monitor host."
echo "Run:"
echo "  ssh -L9090:localhost:9090 root@$(terraform output monitor_ip) &"
echo "And then:"
echo "  xdg-open http://localhost:9090/targets"
echo ""
echo "Have fun! Keep it Encrypted!"
