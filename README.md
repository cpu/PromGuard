# Prometheus stat scraping over WireGuard

## Prerequisites

1. [Install Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html)
1. [Install Terraform](https://www.terraform.io/intro/getting-started/install.html)
1. [Get a DigitalOcean API key](https://cloud.digitalocean.com/settings/api/tokens)
1. Clone this repo and `cd` into it.

## Initial Setup

1. Create `terraform.tfvars` in the root of the project directory
1. Inside of `terraform.tfvars` put:
    ```
    do_token = "YOUR_DIGITAL_OCEAN_API_KEY_HERE"
    do_ssh_key_file = "PATH_TO_YOUR_SSH_PUBLIC_KEY_HERE"
    do_ssh_key_name = "A_NAME_TO_ADD_YOUR_SSH_PUBLIC_KEY_UNDER_IDK_PICK_ONE"
    ```
1. Run `terraform init` to get required plugins

## Usage

1. Run `./run.sh`
