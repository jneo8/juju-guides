# Tutorial juju operator charm

## Summary

In this tutorial we will intruduce how to create a new charm operator with Juju Operator Framework.


## Agenda


- [Prepare](#prepare)
- Sense
    - [What is operator](#what-is-operator)
    - [What is charmcraft](#what-is-charmcraft)
        - [Create new charm project with charmcraft](#create-new-charm-project-with-charmcraft)
        - [Charm Project Structure](#charm-project-structure)



## Prepare

Snap install:

* charmcraft channel==2.0/stable
* lxd
* juju

```sh
$ snap list | grep  -E "charmcraft|lxd|juju"
charmcraft                 2.0.0                       1033   2.x/stable       canonical**   classic
juju                       2.9.33                      20276  2.9/stable       canonical**   classic
lxd                        5.4-1ff8d34                 23367  latest/stable    canonical**   -
```

### Bootstrap juju with local lxd

```sh
# This will create a controller name local-lxd which cloud is lxd
$ juju bootstrap lxd local-lxd
$ juju controllers

Use --refresh option with this command to see the latest information.

Controller  Model    User   Access     Cloud/Region         Models  Nodes    HA  Version
local-lxd*  default  admin  superuser  localhost/localhost       2      1  none  2.9.33  

$ lxc list 

+---------------+---------+----------------------+------+-----------------+-----------+
|     NAME      |  STATE  |         IPV4         | IPV6 |      TYPE       | SNAPSHOTS |
+---------------+---------+----------------------+------+-----------------+-----------+
| juju-9e3f77-0 | RUNNING | 10.127.138.73 (eth0) |      | CONTAINER       | 0         |
+---------------+---------+----------------------+------+-----------------+-----------+
```

### What is Operator

[kubernetes: Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)


## What is charmcraft

Charmcraft enables charm creators to build, publish, and manage charmed operators for Kubernetes, metal and virtual machnes.

### Create new charm project with charmcraft

```sh
$ charmcraft init -p charm-nginx

$ tree charm-nginx

charm-nginx
├── actions.yaml
├── charmcraft.yaml
├── config.yaml
├── CONTRIBUTING.md
├── LICENSE
├── metadata.yaml
├── README.md
├── requirements-dev.txt
├── requirements.txt
├── run_tests
├── src
│   └── charm.py
└── tests
    ├── __init__.py
        └── test_charm.py
```

### Charm Project Structure

First is the `charmcraft.yaml`.

```
type: "charm"
bases:
  - build-on:
    - name: "ubuntu"
      channel: "20.04"
    run-on:
    - name: "ubuntu"
      channel: "20.04"
```

Basic it's a configuration tell `charmcraft` how to build and publish charm. You can refer the details on [Official document](https://juju.is/docs/sdk/charmcraft-config)

second is the `requirements.txt`. It's the place we define python dependency.

```
ops >= 1.4.0
```

Now you can try to build your first charm. In default, charmcraft will use lxd to build your charm file.

The charm is just a zipfile with metadata and the operator code itself.

```sh
$ charmcraft pack -v

# Now you can see there is a lxd container in project charmcraft
# which is building our charm
$ lxc list --project charmcraft

$ ls | grep *.charm

charm-nginx_ubuntu-20.04-amd64.charm

# You can use those commands to see what's inside the charm.

$ unzip -l charm-nginx_ubuntu-20.04-amd64.charm
$ unzip -l charm-nginx_ubuntu-20.04-amd64.charm  | awk '{print $4}' | awk -F '/' '{print $1}' | uniq
$ unzip -l charm-nginx_ubuntu-20.04-amd64.charm | grep metadata
$ unzip -l charm-nginx_ubuntu-20.04-amd64.charm | grep config
$ unzip -l charm-nginx_ubuntu-20.04-amd64.charm | grep src
```


## Deploy bundle

`charm-nginx/bundles/focal.yaml`

```yaml
name: nginx

description: |
  nginx charm for tutorial
series: focal
applications:
  nginx:
    charm: ./charm-nginx/charm-nginx_ubuntu-20.04-amd64.charm
    num_units: 1
```

```sh
$ juju add-model juju-tutorial
$ juju models
# This will deploy our bundle to model 
$ juju deploy ./bundles/focal.yaml
$ juju status
# You should see another lxc container has been created
$ lxc list

$ juju ssh nginx/0

# Inside unit

# unit log
$ tail /var/log/juju/unit-nginx-0.log

# This will show juju agent process, more details: https://juju.is/docs/olm/agents
$ ps aux | grep juju

# This is our charm file in the unit
$ ls /var/lib/juju/agents/unit-nginx-0/charm

LICENSE  README.md  actions.yaml  config.yaml  dispatch  hooks  manifest.yaml  metadata.yaml  revision  src  venv
```

This is the place where magic happen. We will go back here after we finish our charm, now we can just delete our model.

```sh
$ juju destroy-model juju-tutorial
```

## Deployment


## Destroy

```sh
# Destroy model
$ juju destroy-model juju-tutorial
```
