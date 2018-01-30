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

## Example Run

[![asciicast](https://asciinema.org/a/RUGQCKxe8UAPPAMXtfRXrW33F.png)](https://asciinema.org/a/RUGQCKxe8UAPPAMXtfRXrW33F)

![Network Diagram](https://raw.githubusercontent.com/cpu/promguard/master/PromGuard.Network.Diagram.png)

![Configured Targets](https://binaryparadox.net/d/3b89f9a4-b2f4-4c1e-bfcc-96cf085c4bcb.jpg)

Monitor firewall rules:
```
root@promguard-monitor-1:~# ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                   # OpenSSH
51820/udp                  ALLOW       Anywhere                   # WireGuard
22/tcp (v6)                ALLOW       Anywhere (v6)              # OpenSSH
51820/udp (v6)             ALLOW       Anywhere (v6)              # WireGuard
```

Monitor WireGuard interface status:
```
root@promguard-monitor-1:~# wg
interface: wg0
  public key: TxMVo4TkXvp+Av44qL1TiW1E0m6qhdM48E/L8AxdYj4=
  private key: (hidden)
  listening port: 51820

peer: uJIL7F6e/02Z4byfX2Tl+WRrAu7SXLt6FpP3WBum3U8=
  endpoint: 178.62.105.97:51820
  allowed ips: 10.0.0.2/32
  latest handshake: 1 minute, 47 seconds ago
  transfer: 240.56 KiB received, 21.58 KiB sent

peer: oJ0y/SGhq4ebIT1m2Ago4/W4/opkeY9WzKLrxFyxlWw=
  endpoint: 128.199.186.30:51820
  allowed ips: 10.0.0.4/32
  latest handshake: 1 minute, 48 seconds ago
  transfer: 242.62 KiB received, 21.58 KiB sent

peer: MOCzYMLelX8uo2WaU/y/xSBRUUphPPoMNl8FymHOGlU=
  endpoint: 138.197.207.168:51820
  allowed ips: 10.0.0.3/32
  latest handshake: 1 minute, 49 seconds ago
  transfer: 241.71 KiB received, 21.58 KiB sent
```

Example Node Firewall Status:

```
root@promguard-node-3:~# ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                   # OpenSSH
51820/udp                  ALLOW       Anywhere                   # WireGuard
10.0.0.4 9100/tcp          ALLOW       10.0.0.1                   # promguard-monitor-1 WireGuard node-exporter scraper
22/tcp (v6)                ALLOW       Anywhere (v6)              # OpenSSH
51820/udp (v6)             ALLOW       Anywhere (v6)              # WireGuard
```

Example Node WireGuard interface status:
```
root@promguard-node-3:~# wg
interface: wg0
  public key: oJ0y/SGhq4ebIT1m2Ago4/W4/opkeY9WzKLrxFyxlWw=
  private key: (hidden)
  listening port: 51820

peer: TxMVo4TkXvp+Av44qL1TiW1E0m6qhdM48E/L8AxdYj4=
  endpoint: 165.227.33.184:51820
  allowed ips: 10.0.0.1/32
  latest handshake: 31 seconds ago
  transfer: 25.50 KiB received, 285.54 KiB sent
```
