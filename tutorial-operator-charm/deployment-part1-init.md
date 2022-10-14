# Deployment - Init

## Create charm project and clean

```sh
$ charmcraft init -p charm-redis
```

First is `./src/charm.py`

First we should delete all `observer` function here. We will start deploy from empty class.

Also delete `containers` and `resources` in `metadata.yaml`


## Define charm(metadata.yaml)

`metadata.yaml`

First is the basic information

```yaml
name: redis-k8s
display-name: Redis
docs: https://discourse.charmhub.io/t/redis-docs-index/4571
description: >
  Redis charm for Kubernetes deployments.
tags:
  - database
  - storage
  - kubernetes
  - redis
summary: >
  Redis is an open source (BSD licensed), in-memory data structure store, used
  as a database, cache, and message broker. Redis provides data structures
  such as strings, hashes, lists, sets, sorted sets with range queries,
  bitmaps, hyperloglogs, geospatial indexes, and streams. Redis has built-in
  replication, Lua scripting, LRU eviction, transactions, and different levels
  of on-disk persistence, and provides high availability via Redis Sentinel and
  automatic partitioning with Redis Cluster.

  This charm supports Redis in Kubernetes environments, using k8s services
  for load balancing. This supports a simple Redis topology. Although multiple
  units are allowed, replication and clustering are not supported for the moment.

...
```

Then the details of our charm's relation, resource, and storage.

Here we define our charm which provide a redis interface. you can find interface defininatation on [charms.redis_k8s.v0.redis](https://charmhub.io/redis-k8s/libraries/redis).

**containers**

Then we define an container name **redis**, which use oci-image resource as it's image as redis node.

And a sentinel container as sentinel node.

**resources**

The resource **redis-image** define that we can deploy local image use command `--resource redis-image=${local_image_path}`, which is useful in local environment when the image is not published.

Also define the certificate files for the redis server.

**storage**

Require a storage mount at `/var/lib/redis`

[details here](https://juju.is/docs/sdk/metadata-reference)

**peers**

The redis unit relate to each other with the interface `redis-peers`

[peers relation](https://juju.is/docs/sdk/relations#heading--peer-relations)

```yaml

...

provides:
  redis:
    interface: redis

containers:
  redis:
    resource: redis-image
    mounts:
      - storage: database
        location: /var/lib/redis
  sentinel:
    resource: redis-image

resources:
  redis-image:
    type: oci-image
    description: ubuntu lts docker image for redis
    upstream: dataplatformoci/redis:7.0-22.04_edge
  cert-file:
    type: file
    filename: redis.crt
  key-file:
    type: file
    filename: redis.key
  ca-cert-file:
    type: file
    filename: ca.crt

storage:
  database:
    type: filesystem
    location: /var/lib/redis

peers:
  redis-peers:
    interface: redis-peers
```

## Charm(python class)

We are going to implement the charm's code.

First please create a empth class with the same name as the one in the `src/charm.py`(delete the old one also)
And this class should inherit `CharmBase`.  All charms written using the Charmed Operator Framework must use this abstraction.

And the basic `__init__` function. We can define basic information of the charm: juju unit name, juju application name, and the kubernetes namespace name.



```python
from ops.charm import CharmBase
from literals import (
    LEADER_HOST_KEY,
    PEER,
    PEER_PASSWORD_KEY,
    REDIS_PORT,
    SENTINEL_PASSWORD_KEY,
    SOCKET_TIMEOUT,
    WAITING_MESSAGE,
)
from exceptions import RedisFailoverCheckError, RedisFailoverInProgressError

class RedisK8sCharm(CharmBase):
    """Charm the service.

    Deploy a standalone instance of redis-server, using Pebble as an entry
    point to the service.
    """

    def __init__(self, *args):
        super().__init__(*args)

        self._unit_name = self.unit.name
        self._name = self.model.app.name
        self._namespace = self.model.name

if __name__ == "__main__":  # pragma: nocover
    main(RedisK8sCharm)
```

**Both literals and exceptions will be used later in our deployment. Nothing special here.**

`src/literals.py`

```python
"""Literals used by the Redis charm."""

WAITING_MESSAGE = "Waiting for Redis..."
PEER = "redis-peers"
PEER_PASSWORD_KEY = "redis-password"
SENTINEL_PASSWORD_KEY = "sentinel-password"
LEADER_HOST_KEY = "leader-host"
SOCKET_TIMEOUT = 1

REDIS_PORT = 6379
SENTINEL_PORT = 26379

CONFIG_DIR = "/etc/redis-server"
SENTINEL_CONFIG_PATH = f"{CONFIG_DIR}/sentinel.conf"
```

`./src/exceptions.py`

```python
"""Module with custom exceptions related to the Redis charm."""


class RedisOperatorError(Exception):
    """Base class for exceptions in this module."""

    def __repr__(self):
        """String representation of the Error class."""
        return "<{}.{} {}>".format(type(self).__module__, type(self).__name__, self.args)

    @property
    def name(self):
        """Return a string representation of the model plus class."""
        return "<{}.{}>".format(type(self).__module__, type(self).__name__)

    @property
    def message(self):
        """Return the message passed as an argument."""
        return self.args[0]


class RedisFailoverInProgressError(RedisOperatorError):
    """Exception raised when failover is in progress."""


class RedisFailoverCheckError(RedisOperatorError):
    """Exception raised when failover status cannot be checked."""
```
