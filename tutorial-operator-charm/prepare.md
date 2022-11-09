# Prepare

## Snap dependency

We are going to use microk8s to deploy kubernetes locally, charmcraft for initial, build, and release charm package, and juju to deploy charm inside the microk8s.

Snap install:

* charmcraft channel==2.0/stable
* microk8s
* juju

```sh
$ snap list | grep  -E "charmcraft|microk8s|juju"
charmcraft         2.0.0                       1033   latest/stable    canonical**  classic
juju               2.9.34                      20510  latest/stable    canonical**  classic
microk8s           v1.25.2                     4055   1.25/stable      canonical**  classic
```

## Microk8s enable addons

```sh
$ microk8s status
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    hostpath-storage     # (core) Storage class; allocates storage from host directory
    storage              # (core) Alias to hostpath-storage add-on, deprecated
  disabled:
    community            # (core) The community addons repository
    dashboard            # (core) The Kubernetes dashboard
    gpu                  # (core) Automatic enablement of Nvidia CUDA
    helm                 # (core) Helm 2 - the package manager for Kubernetes
    helm3                # (core) Helm 3 - Kubernetes package manager
    host-access          # (core) Allow Pods connecting to Host services smoothly
    ingress              # (core) Ingress controller for external access
    mayastor             # (core) OpenEBS MayaStor
    metallb              # (core) Loadbalancer for your Kubernetes cluster
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
    prometheus           # (core) Prometheus operator for monitoring and logging
    rbac                 # (core) Role-Based Access Control for authorisation
    registry             # (core) Private image registry exposed on localhost:32000
```

## Bootstrap juju with microk8s

Juju bootstrap consists of creating a controller's model and provisioning a machine to act as controller.

https://juju.is/docs/olm/juju-bootstrap


```sh
# This will create a controller name micro which cloud is microk8s
$ juju bootstrap microk8s micro
$ juju controllers

Use --refresh option with this command to see the latest information.

Controller  Model    User   Access     Cloud/Region         Models  Nodes    HA  Version
micro*      traefik  admin  superuser  microk8s/localhost        1      1     -  2.9.34  
```

## Summary

Here we initial the basic environment we need to deploy juju charm.
We will introduce basic **charmcraft** usage in [next chapter: Charmcraft](./charmcraft.md)
