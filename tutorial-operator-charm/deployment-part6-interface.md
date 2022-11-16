# Deployment - Redis Interface

To provide the interface for another charm to connect to redis. We are going to implement provider of [redis interface](https://charmhub.io/redis-k8s/libraries/redis).
Use charmcraft to download the lib from charmhub. The lib will be download in the **lib** folder.

> [Juju Integration](https://juju.is/docs/sdk/integration)

```sh
$ charmcraft fetch-lib charms.redis-k8s.v0.redis
$ tree
.
├── actions.yaml
├── charmcraft.yaml
├── config.yaml
├── CONTRIBUTING.md
├── lib
│   └── charms
│       └── redis_k8s
│           └── v0
│               └── redis.py
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

Then register our charm class as redis provider.
It will register a `_on_relation_changed` function to event `redis_event_change`.
The `_on_relation_changed` event is triggered whenever there is a change to the integration data.


```python
...
from charms.redis_k8s.v0.redis import RedisProvides
...

class RedisK8sCharm(CharmBase):
    ...

    def __init__(self, *args):
	...
	self.redis_provides = RedisProvides(self, port=REDIS_PORT)
```

`src/literals.py`

```python
"""Literals used by the Redis charm."""

REDIS_PORT = 6379
```

Lets look at the interface details: `lib/charms/redis_k8s/v0/redis.py`.
One thing interesting is that it's also an `operator.framework.Objects` class just like the sentinel we created in previous chapter, but it only handle the `redis_relation_changed` event.
It will be triggered once the juju relation be applyed between the applications.

```python
...

class RedisProvides(Object):
    def __init__(self, charm, port):
        """A class implementing the redis provides relation."""
        super().__init__(charm, "redis")
        self.framework.observe(charm.on.redis_relation_changed, self._on_relation_changed)
        self._port = port
        self._charm = charm

    def _on_relation_changed(self, event):
        """Handle the relation changed event."""
        event.relation.data[self.model.unit]['hostname'] = self._get_master_ip()
        event.relation.data[self.model.unit]['port'] = str(self._port)
        # The reactive Redis charm also exposes 'password'. When tackling
        # https://github.com/canonical/redis-k8s/issues/7 add 'password'
        # field so that it matches the exposed interface information from it.
        # event.relation.data[self.unit]['password'] = ''

    def _bind_address(self, event):
        """Convenience function for getting the unit address."""
        relation = self.model.get_relation(event.relation.name, event.relation.id)
        if address := self.model.get_binding(relation).network.bind_address:
            return address
        return self.app.name

    def _get_master_ip(self) -> str:
        """Gets the ip of the current redis master."""
        return socket.gethostbyname(self._charm.current_master)
```

And create a event handler for the event `redis_relation_created`. Triggered when a new integration is created. This can occur before applications have started.

```python
class RedisK8sCharm(CharmBase):
    ...

    def __init__(self, *args):
        ...
        self.framework.observe(self.on.redis_relation_created, self._on_redis_relation_created)


    def _on_redis_relation_created(self, event):
        """Handle the relation created event."""
        if not self.unit.is_leader():
            return

        self._peers.data[self.app]["enable-password"] = "false"
        self._update_layer()

        # update_layer will set a Waiting status if Pebble is not ready
        if not isinstance(self.unit.status, ActiveStatus):
            event.defer()
            return
```
