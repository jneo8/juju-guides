# Tutorial juju operator charm

## Summary

In this tutorial we will intruduce how to create a new charm operator with Juju Operator Framework.


## Prepare

Snap install:

* charmcraft channel==2.0/stable
* lxd
* juju

```bash
$ snap list | grep  -E "charmcraft|lxd|juju"
charmcraft                 2.0.0                       1033   2.x/stable       canonical**   classic
juju                       2.9.33                      20276  2.9/stable       canonical**   classic
lxd                        5.4-1ff8d34                 23367  latest/stable    canonical**   -
```

## What is charmcraft?

Charmcraft enables charm creators to build, publish, and manage charmed operators for Kubernetes, metal and virtual machnes.


## Create new charm project with charmcraft


```bash
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

```bash
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

### What is Operator?

[kubernetes: Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
It's more like a 
