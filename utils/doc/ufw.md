# UFW ports

## Network ranges
* 10.42.0.0/16 **coldnet**
  * 10.42.0.1/32 **innernet**
  * 10.42.13.0/24 **admin**
  * 10.42.10.0/24 **nodes**
  * 10.42.11.0/24 **storage**
  * 10.42.20.0/24 **portals**

## Examples
```sh
# Allow every to access a port from a certain ip range
ufw allow from <range> to any port <port>
```

## Ports for each kind of servers
### Innernet
**Ports for an Innernet server**
* 51820 | Anywhere | *wireguard server*

### Manager
**Ports for a manager server**
* **SSH**:
  * 22   | 10.42.13.0/24 | *ssh server*
* **Nomad**:
  * 4646 | 10.42.0.0/16  | *http server*
  * 4647 | 10.42.10.0/24 | *rpc server*
  * 4648 | 10.42.10.0/24 | *serf server*
* **Consul**:
  * 8500 | 10.42.0.0/16 | *http server*
  * 8600 | 10.42.0.0/16 | *dns server*
  * 8300 | 10.42.0.0/16 | *rpc server*
  * 8301 | 10.42.0.0/16 | *lan serf server*
  * 8302 | 10.42.0.0/16 | *wan serf server*
* **Vault**:
  * 8500 | 10.42.0.0/16  | *http server*

## Portal
* **Traefik**:
  * 80  | Anywhere | *http server*
  * 443 | Anywhere | *https server*