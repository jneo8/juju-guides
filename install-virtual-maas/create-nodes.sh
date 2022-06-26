#!/bin/bash
for i in {0..4}; do
    	sudo virt-install --name=maas-node-${i} --vcpus=2 --memory=4096 \
    	--virt-type=kvm --pxe --boot network,hd \
    	--os-variant=ubuntu20.04 --graphics vnc --noautoconsole --accelerate \
	--disk /var/lib/libvirt/images/maas-node-${i}-disk1.qcow2,bus=virtio,format=qcow2,cache=none,sparse=true,size=32,serial=maas-node-${i}-disk1 \
	--disk /var/lib/libvirt/images/maas-node-${i}-disk2.qcow2,bus=virtio,format=qcow2,cache=none,sparse=true,size=32,serial=maas-node-${i}-disk2 \
    	--network bridge=virbr0  # note bridge order matters if multiple bridges specified
done
