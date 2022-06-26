SHELL := /bin/bash

##@ maas

get-maas-node-uuid:  ## Get maas nodes uuid
	sudo virsh list --all | grep maas-node | awk '{print $$2}' | xargs -L 1 -i  sh -c "echo {}; sudo virsh dominfo {}; sudo virsh domiflist {}"

.PHONY: get-maas-node-uuid


##@ Help

.PHONY: help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help
