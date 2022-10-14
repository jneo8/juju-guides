# Prepare


## Snap dependency

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

## Bootstrap juju with microk8s

```sh
# This will create a controller name local-lxd which cloud is lxd
$ juju bootstrap microk8s micro
$ juju controllers

Use --refresh option with this command to see the latest information.

Controller  Model    User   Access     Cloud/Region         Models  Nodes    HA  Version
micro*      traefik  admin  superuser  microk8s/localhost        1      1     -  2.9.34  

$ microk8s enable dns metallb hostpath-storage

$ microk8s status
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
    hostpath-storage     # (core) Storage class; allocates storage from host directory
    metallb              # (core) Loadbalancer for your Kubernetes cluster
    storage              # (core) Alias to hostpath-storage add-on, deprecated
  disabled:
    cert-manager         # (core) Cloud native certificate management
    community            # (core) The community addons repository
    dashboard            # (core) The Kubernetes dashboard
    gpu                  # (core) Automatic enablement of Nvidia CUDA
    host-access          # (core) Allow Pods connecting to Host services smoothly
    ingress              # (core) Ingress controller for external access
    kube-ovn             # (core) An advanced network fabric for Kubernetes
    mayastor             # (core) OpenEBS MayaStor
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
    observability        # (core) A lightweight observability stack for logs, traces and metrics
    prometheus           # (core) Prometheus operator for monitoring and logging
    rbac                 # (core) Role-Based Access Control for authorisation
    registry             # (core) Private image registry exposed on localhost:32000
```
