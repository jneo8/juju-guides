SHELL := /bin/bash

##@ maas

start-maas-controller:  ## Start maas controller
	sudo virsh start maas-controller
	sudo virsh list

get-maas-node-uuid:  ## Get maas nodes uuid
	sudo virsh list --all | grep "maas-node" | awk '{print $$2}' | xargs -L 1 sudo virsh dominfo

get-maas-node-mac-addresses:  ## Get maas mac addresses
	sudo virsh list --all | grep "maas-node" | awk '{print $$2}' | xargs -L 1 sudo virsh domiflist

.PHONY: get-maas-node-mac-addresses get-maas-node-uuid start-maas-controller


##@ Help

.PHONY: help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
