# Deployment - redis-peers interface

Peer relation is the recommended way to implement the relation for those distributed system like MongoDB, PostgreSQL, and ElasticSearch where clusters must exchange information amongst one another to perform proper clustering.

> More details: [Peer relation](https://juju.is/docs/sdk/relations#heading--peer-relations)

We need to handle `relation_departed` and `relation_changed` event for our peers relation.


## peer_relation_changed

```mermaid
stateDiagram-v2

[*] --> peer_relatoin_changed

peer_relatoin_changed --> is_current_master_and_leader
is_current_master_and_leader --> update_application_master: true

note left of update_application_master : This will get master information from sentinel and store master ip in peer relation databag

is_current_master_and_leader --> is_leader_and_event_unit: false
update_application_master --> is_leader_and_event_unit

is_leader_and_event_unit --> [*]: false
is_leader_and_event_unit --> is_sentinel_in_majority: true
is_sentinel_in_majority --> WaitingStatus: false
WaitingStatus --> event_defer
event_defer --> [*]
is_sentinel_in_majority --> update_quorum: true
note left of update_quorum
    This will broadcast command
    "SENTINEL SET {self._name} quorum {self.sentinel.expected_quorum}"
    and exec on all sentinel instances.
end note

update_quorum --> ActiveStatus
ActiveStatus --> [*]
```

```python
...

class RedisK8sCharm(CharmBase):
    ...

    def __init__(self, *args):
        ...

        self.framework.observe(self.on[PEER].relation_changed, self._peer_relation_changed)
        ...

    def _peer_relation_changed(self, event):
        """Handle relation for joining units."""
        if not self._check_master():
            if self.unit.is_leader():
                # Update who the current master is
                self._update_application_master()

        if not (self.unit.is_leader() and event.unit):
            return

        if not self.sentinel.in_majority:
            self.unit.status = WaitingStatus("Waiting for majority")
            event.defer()
            return

        # Update quorum for all sentinels
        self._update_quorum()

        self.unit.status = ActiveStatus()

    def _check_master(self) -> bool:
        """Connect to the current stored master and query role."""
        with self._redis_client(hostname=self.current_master) as redis:
            try:
                result = redis.execute_command("ROLE")
            except (ConnectionError, TimeoutError) as e:
                logger.warning("Error trying to check master: {}".format(e))
                return False

            if result[0] == "master":
                return True

        return False

    def _update_application_master(self) -> None:
        """Use Sentinel to update the current master hostname."""
        info = self.sentinel.get_master_info()
        logger.debug(f"Master info: {info}")
        if info is None:
            logger.warning("Could not update current master")
            return

        self._peers.data[self.app][LEADER_HOST_KEY] = info["ip"]

    def _update_quorum(self) -> None:
        """Connect to all Sentinels deployed to update the quorum."""
        command = f"SENTINEL SET {self._name} quorum {self.sentinel.expected_quorum}"
        self._broadcast_sentinel_command(command)

    def _broadcast_sentinel_command(self, command: str) -> None:
        """Broadcast a command to all sentinel instances.

        Args:
            command: string with the command to broadcast to all sentinels
        """
        hostnames = [self._k8s_hostname(unit.name) for unit in self._peers.units]
        # Add the own unit
        hostnames.append(self.unit_pod_hostname)

        for hostname in hostnames:
            with self.sentinel.sentinel_client(hostname=hostname) as sentinel:
                try:
                    logger.debug("Sending {} to sentinel at {}".format(command, hostname))
                    sentinel.execute_command(command)
                except (ConnectionError, TimeoutError) as e:
                    logger.error("Error connecting to instance: {} - {}".format(hostname, e))

    @contextmanager
    def _redis_client(self, hostname="localhost") -> Redis:
        """Creates a Redis client on a given hostname.

        All parameters are passed, will default to the same values under `Redis` constructor

        Returns:
            Redis: redis client
        """
        ca_cert_path = self._retrieve_resource("ca-cert-file")
        client = Redis(
            host=hostname,
            port=REDIS_PORT,
            password=self._get_password(),
            ssl=self.config["enable-tls"],
            ssl_ca_certs=ca_cert_path,
            decode_responses=True,
            socket_timeout=SOCKET_TIMEOUT,
        )
        try:
            yield client
        finally:
            client.close()

    def _k8s_hostname(self, name: str) -> str:
        """Create a DNS name for a Redis unit name.

        Args:
            name: the Redis unit name, e.g. "redis-k8s-0".

        Returns:
            A string representing the hostname of the Redis unit.
        """
        unit_id = name.split("/")[1]
        return f"{self._name}-{unit_id}.{self._name}-endpoints.{self._namespace}.svc.cluster.local"

    @property
    def current_master(self) -> Optional[str]:
        """Get the current master."""
        return self._peers.data[self.app].get(LEADER_HOST_KEY)
```

## peer_relation_departed

Handle relation for leaving units.


```mermaid
stateDiagram-v2

[*] --> _peer_relation_departed

_peer_relation_departed --> is_leader
is_leader --> [*]: false
is_leader --> is_master: true
is_master --> update_application_master: false
update_application_master --> update_quorum
is_master --> update_quorum: true
update_quorum --> is_failover_finish

%% is_failover_finish
note right of is_failover_finish
    Check if failover is still in progress.
end note
is_failover_finish --> WaitingStatus: error
WaitingStatus --> event_defer
event_defer --> [*]
is_failover_finish --> sentinel_failover: true


%% sentinel_failover
note left of sentinel_failover
    Try to failover the current master.
    Should only be called from juju leader. 
    Execute "SENTINEL FAILOVER {self.name}" on sentinel instance.
end note
sentinel_failover --> BlockStatus: RedisError
BlockStatus --> [*]
sentinel_failover --> reset_sentinel: true

%% reset_sentinel
note right of reset_sentinel
    broadcast command
    "SENTINEL RESET {self.name}"
    and exec on all sentinel instances
end note
reset_sentinel --> ActiveStatus
ActiveStatus --> [*]

```

```python
...

from ops.model import BlockedStatus
from redis.exceptions import RedisError
from exceptions import RedisFailoverCheckError, RedisFailoverInProgressError

...

class RedisK8sCharm(CharmBase):
    ...

    def __init__(self, *args):

        ...

        self.framework.observe(self.on[PEER].relation_departed, self._peer_relation_departed)
        ...

    def _peer_relation_departed(self, event):
        """Handle relation for leaving units."""
        if not self.unit.is_leader():
            return

        if not self._check_master():
            self._update_application_master()

        # Quorum is updated beforehand, since removal of more units than current majority
        # could lead to the cluster never reaching quorum.
        logger.info("Updating quorum")
        self._update_quorum()

        try:
            self._is_failover_finished()
        except (RedisFailoverCheckError, RedisFailoverInProgressError):
            msg = "Failover didn't finish, deferring"
            logger.info(msg)
            self.unit.status == WaitingStatus(msg)
            event.defer()
            return

        try:
            self._sentinel_failover(event.departing_unit.name)
        except RedisError as e:
            msg = f"Error on failover: {e}"
            logger.error(msg)
            self.unit.status == BlockedStatus(msg)
            return

        logger.info("Resetting sentinel")
        self._reset_sentinel()

        self.unit.status = ActiveStatus()

    def _is_failover_finished(self) -> None:
        """Check if failover is still in progress."""
        logger.warning("Checking if failover is finished.")
        info = self.sentinel.get_master_info()
        if info is None:
            logger.warning("Could not check failover status")
            raise RedisFailoverCheckError

        if "failover-state" in info:
            logger.warning(
                "Failover taking place. Current status: {}".format(info["failover-state"])
            )
            raise RedisFailoverInProgressError

    def _sentinel_failover(self, departing_unit_name: str) -> None:
        """Try to failover the current master.

        This method should only be called from juju leader, to avoid more than one
        sentinel sending failovers concurrently.
        """
        if self._k8s_hostname(departing_unit_name) != self.current_master:
            # No failover needed
            return

        with self.sentinel.sentinel_client() as sentinel:
            sentinel.execute_command(f"SENTINEL FAILOVER {self._name}")

    def _reset_sentinel(self):
        """Reset sentinel to process changes and remove unreachable servers/sentinels."""
        command = f"SENTINEL RESET {self._name}"
        self._broadcast_sentinel_command(command)
```

