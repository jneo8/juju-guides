# juju life-cycle

## What is lifecycle?

$$lifecycle=hooks+states$$


## What is hook/event?

- A hook is an event handler.
- An event is a data structure that encapsulates part of the execution context of a charm

https://github.com/juju/charm/blob/master/hooks/hooks.go
[import at](https://github.com/juju/juju/blob/915c77761ef1b1f2f0abbc2c386fde54cf848f89/go.mod#L51)

### How hook run?

https://github.com/juju/juju/blob/2.9/worker/uniter/operation/runhook.go

## [Juju status](https://github.com/juju/juju/blob/2.9/core/status/status.go)

| status             | types                               |
| ------------------ | ----------------------------------- | 
| error              | machine-agent, unit-agent           | 
| started            | machine-agent, unit-agent           | 
| pending            | machine-agent                       | 
| stopped            | machine-agent                       | 
| down               | machine-agent                       | 
| allocating         | unit-agent                          | 
| rebooting          | unit-agent                          | 
| executing          | unit-agent                          | 
| idle               | unit-agent                          | 
| failed             | unit-agent                          | 
| lost               | unit-agent                          | 
| unset              | application-software, unit-software | 
| maintenance        | application-software, unit-software | 
| terminated         | application-software, unit-software | 
| unknown            | application-software, unit-software | 
| waiting            | application-software, unit-software | 
| blocked            | application-software, unit-software | 
| active             | application-software, unit-software | 
| attaching          | storage                             | 
| attached           | storage                             | 
| detaching          | storage                             | 
| detached           | storage                             | 
| available          | models                              | 
| busy               | models                              | 
| joining            | relation                            | 
| joined             | relation                            | 
| broken             | relation                            | 
| suspending         | relation                            | 
| suspended          | relation                            | 
| destroying         | common                              | 
| empty              | instance                            | 
| provisioning       | instance                            | 
| running            | instance                            | 
| provisioning error | instance                            | 
| applied            | modification                        | 


## juju lifecycle


The juju operator framework implement Observer pattern

```mermaid
flowchart TD


%%
%% Setup
%%

setup_relation_created["[*]-relation-created"]
setup_config_changed[config-changed]
setup_leader_settings_changed[leader-settings-changed]
setup_leader_elected[leader-elected]
setup_start_1[start]
setup_start_2[start]


subgraph Setup
    setup_start_1 --> install
    install --> setup_relation_created

    setup_relation_created --non_leader_unit--> setup_leader_settings_changed
    setup_relation_created --leader_unit--> setup_leader_elected
    setup_leader_settings_changed --> setup_config_changed
    setup_leader_elected --> setup_config_changed
    setup_config_changed --> setup_start_2
end

Setup --> Operation

%%
%% Operation
%%

operation_leader_elected[leader-elected]
operation_leader_settings_changed[leader-settings-changed]

operation_relation_joined["[*]-relation-joined"]
operation_relation_departed["[*]-relation-departed"]
operation_relation_changed["[*]-relation-changed"]
operation_relation_created["[*]-relation-created"]
operation_relation_broken["[*]-relation-broken"]

operation_storage_attected["[*]-storage-atteched"]
operation_storage_detected["[*]-storage-deteched"]

operation_upgrade_charm[upgrade-charm]
operation_update_status[update-status]
operation_config_changed[config-changed]
operation_collect_metrics[collect-metrics]

subgraph Operation

    operation_collect_metrics
    operation_upgrade_charm
    operation_update_status
    operation_config_changed

    subgraph Leader
    operation_leader_elected --- operation_leader_settings_changed
    end

    subgraph Relation
    operation_relation_joined --> operation_relation_changed
    operation_relation_joined -.- operation_relation_departed

    operation_relation_created -.- operation_relation_broken
    end

    subgraph Storage
    operation_storage_attected -.- operation_storage_detected
    end

end

%%
%% Teardown
%%
Operation --> Teardown


teardown_relation_broken["[*]-relation-broken"]
teardown_storage_detached["[*]-storage-deteched"]
teardown_stop["stop"]
teardown_remove["remove"]

subgraph Teardown

    teardown_relation_broken
    --> teardown_storage_detached
    --> teardown_stop
    --> teardown_remove
end

End["(end)"]

Teardown --> End
```

```mermaid
flowchart TD

pre_series_upgrade(pre-series-upgrade)
post_series_upgrade(post-series-upgrade)



subgraph Operation -- Machine
pre_series_upgrade -.- post_series_upgrade
end


action("[*]-action")
custom_event("[custom_event_name]")
pebble_ready("[*]-pebble-ready")

subgraph Anytime
action
custom_event
subgraph Only on kubernetes
pebble_ready
end
end
```

## References

- https://juju.is/docs/sdk/events
- https://juju.is/docs/sdk/event--hook
- [A core lifecycle](https://discourse.charmhub.io/t/core-lifecycle-events/4455)
- [A charm’s life](https://discourse.charmhub.io/t/a-charms-life/5938#heading--legend)
- [Juju state machine documentation and visualization](https://discourse.charmhub.io/t/juju-state-machine-documentation-and-visualization/3511)
- [Juju State diagram](https://miro.com/app/board/o9J_l8NaUVU=/?share_link_id=938178796053)
- [Talking to a workload: control flow from A to Z](https://discourse.charmhub.io/t/talking-to-a-workload-control-flow-from-a-to-z/6161)

### Source code

- https://github.com/juju/juju/tree/2.9/worker/uniter/operation
- https://github.com/juju/charm/blob/master/hooks/hooks.go
