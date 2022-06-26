# Install MAAS on kvm


## Requirement 

- 24GB RAM
- 6 CPUs
- juju

## Install

### Install KVM on host machine

```
./install.sh
```

### After controller vm running

In controller vm


```bash
sudo vim /etc/netplan/50-cloud-init.yaml
```

```
network:
  ethernets:
    enp1s0:
      dhcp4: false
      addresses: [ 192.168.122.2/24 ]
      gateway4: 192.168.122.1
      nameservers:
        addresses: [ 192.168.122.1 ]
```

> The ethernet name(_enp1s0_) may be different on your machine. Update your network configuration using your VM's current network device name.

```bash
sudo netplan apply
ip a
```

```bash
# Should able to ssh into the vm from host machine
ssh ubuntu@192.168.122.2
```

### Install && configuration maas

https://maas.io/docs

#### Make maas controller can connect to host machine's hypervisor

* Create a SSH key on the maas-controller
* Adding the public key to the host machine's `~/.ssh/authorized_keys`

```bash
# Confirm working

# Enter maas shell in maas-controller
sudo snap run --shell maas

virsh -c qemu+ssh://user@192.168.122.1/system list --all
```

https://maas.io/docs/how-to-manage-vm-hosts#heading--set-up-ssh
https://maas.io/docs/how-to-manage-vm-hosts#heading--set-up-ssah-lv


### Create maas nodes


```bash
./create-nodes.sh
```

### Configure and commission the virtual machines

- See "Adding KVMs to MAAS Manually" on https://ubuntu.com/blog/quick-add-kvms-for-maas


- Get address

```bash
make get-maas-node-uuid
get-maas-node-mac-addresses
```

### Make juju work with maas

* Get maas api key in controller

```bash
sudo maas apikey --username=admin > api-key-file
```


* On host

```bash
juju add-cloud --local
juju add-credential virtual-maas-creds
juju bootstrap virtual-maas
```



## References

https://help.ubuntu.com/community/KVM/Installation
