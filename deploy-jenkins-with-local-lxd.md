# Deploy jenkins cluster with local lxd


## Requirement

- Ubuntu server
- lxd
- juju

## Install prepare

### Install LXD

```bash
sudo snap install lxd

lxd init

# Disable IPv6 for lxd
lxc network set lxdbr0 ipv6.address none
```

#### Install juju

```bash
sudo snap install juju --classic

# Check what clouds are known out-of-the-box
juju clouds --all

# Create a juju controller in juju cloud
juju bootstrap

# List juju controllers
lxc list && juju controllers && juju clouds
```



## Deploy


Before deploy, get jenkins.deb download url from the [Jenkins Debian Packages
](https://pkg.jenkins.io/debian-stable/direct/)

```bash
# Replace config release with your jenkins version
juju deploy jenkins --config "release=https://pkg.jenkins.io/debian-stable/direct/jenkins_2.332.3_all.deb"

# Deploy jenkins slave
juju deploy -n 5 jenkins-slave

# Add relation to jenkins & jenkins slave
juju add-relation jenkins jenkins-slave

# Monitor
juju status --relations

# Debug
juju debug-log
```

Expose: Makes an application publicly available over the network.

```bash
juju expose jenkins
```

Now you can visit jenkins at "http://${JUJU_JENKINS_UNIT_ADDRESS}:8080"

Default jenkins's username is `admin`.
Get password by command:

```bash
juju run-action jenkins/0 get-admin-credentials --wait
```
