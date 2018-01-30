# PromGuard - Authenticated/Encrypted Prometheus stat scraping over WireGuard

## Summary

[Prometheus](https://prometheus.io/) doesn't support authentication/encryption
out of box. Scraping metrics over the capital I internet without is a no-go.
Putting mutually authenticated TLS in front is a hassle.

[WireGuard](http://wireguard.com/) is a next-generation VPN technology likely to
be part of the mainline Linux kernel Soon(TM). It is: simple, fast, effective.

Can we configure Prometheus to scrape stats over WireGuard? Of course. This is
a repository showing an example of this approach using
[Terraform](https://www.terraform.io/) and [Ansible](http://ansible.com/) so
you can easily try it yourself with as little as _one command*_.

`*` - _Not counting installing Terraform & Ansible, and configuring
a DigitalOcean API token! Some limitations apply, batteries not included, offer
not valid in Quebec._

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

## Background

_*TODO*_ - _Write the background section_

## Example Run

* An example `./run.sh` invocation recorded with `asciinema`. The IP addresses
  referred to elsewhere in this README match up with this recording.

[![asciicast](https://asciinema.org/a/RUGQCKxe8UAPPAMXtfRXrW33F.png)](https://asciinema.org/a/RUGQCKxe8UAPPAMXtfRXrW33F)

* A small diagram of the resulting infrastructure. One monitor node
  (`promguard-monitor-1`) located in Toronto is configured with a WireGuard
  tunnel to three nodes to be monitored (`promguard-node-1` in London,
  `promguard-node-2` in San Francisco, and `promguard-node-3` in Singapore):

![Network Diagram](https://raw.githubusercontent.com/cpu/promguard/master/PromGuard.Network.Diagram.png)

* Here's what the Prometheus targets interface looks like accessed over a SSH
  port forward to the monitor host. Each target is specified by a WireGuard
  address (`10.0.0.x`):

![Configured Targets](https://binaryparadox.net/d/3b89f9a4-b2f4-4c1e-bfcc-96cf085c4bcb.jpg)

* The monitor host's (`promguard-monitor-1`) firewall is very simple. Nothing
  but SSH and WireGuard here! Strictly speaking this node doesn't even need to
  expose WireGuard since it only connects outbound to the monitored nodes.

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

* Here's what the monitor host's (`promguard-monitor-1`) `wg0` interface status
  looks like. It has one peer configured for each of the nodes (`10.0.0.2`,
  `10.0.0.3`, and `10.0.0.4`):

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

* Here's what an example node's (`promguard-node-3`) firewall looks like. It
  only allows access to the `node_exporter` port (`9100`) over the WireGuard
  interface, and only for the monitor node's source IP (`10.0.0.1`):

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

* An example node's (`promguard-node-3` again) `wg0` interface shows only one
  peer, the monitor host:

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
