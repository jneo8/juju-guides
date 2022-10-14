# What is charmcraft?

Charmcraft enables charm creators to build, publish, and manage charmed operators for Kubernetes, metal and virtual machnes.


### Create new charm project with charmcraft

```sh
$ charmcraft init -p charm-redis

$ tree charm-redis

charm-redis
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

charm-redis_ubuntu-20.04-amd64.charm

# You can use those commands to see what's inside the charm.

$ unzip -l charm-redis_ubuntu-20.04-amd64.charm
$ unzip -l charm-redis_ubuntu-20.04-amd64.charm  | awk '{print $4}' | awk -F '/' '{print $1}' | uniq
$ unzip -l charm-redis_ubuntu-20.04-amd64.charm | grep metadata
$ unzip -l charm-redis_ubuntu-20.04-amd64.charm | grep config
$ unzip -l charm-redis_ubuntu-20.04-amd64.charm | grep src
```


## Deploy bundle

`charm-redis/bundles/focal.yaml`

```yaml
name: redis

description: |
  redis charm for tutorial
series: focal
applications:
  redis:
    charm: ./charm-redis/charm-redis_ubuntu-20.04-amd64.charm
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

$ juju ssh redis/0

# Inside unit

# unit log
$ tail /var/log/juju/unit-redis-0.log

# This will show juju agent process, more details: https://juju.is/docs/olm/agents
$ ps aux | grep juju

# This is our charm file in the unit
$ ls /var/lib/juju/agents/unit-redis-0/charm

LICENSE  README.md  actions.yaml  config.yaml  dispatch  hooks  manifest.yaml  metadata.yaml  revision  src  venv
```

This is the place where magic happen. We will go back here after we finish our charm, now we can just delete our model.

```sh
$ juju destroy-model juju-tutorial
```
