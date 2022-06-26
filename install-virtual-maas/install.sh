#! /bin/bash

# Script from https://docs.google.com/document/d/1PgGUi4Ifz6JHSmoLzDWmrCCfzD4x9yKA6EwjduMgC3s/edit#


# Load environment varible from .env

dotenv () {
  set -a
  [ -f .env ] && . .env
  set +a
}

dotenv


# Install kvm
# https://help.ubuntu.com/community/KVM/Installation
kvm-ok

sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils -y

sudo adduser `id -un` libvirt

output=$(sudo virsh net-list)

if echo ${output} | grep -q "default"
then 
    sudo virsh net-undefine default
    sudo virsh net-destroy --network default
fi

output=$(sudo virsh net-list)

if ! echo ${output} | grep -q "maas"
then 
    sudo virsh net-define ./virbr0.xml
    sudo virsh net-start maas
    sudo virsh net-autostart maas
fi

if [ ! -f ./focal-server-cloudimg-amd64.img ]
then
    wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    qemu-img info ./focal-server-cloudimg-amd64.img
fi

if [ ! -f disk.img ]
then
    qemu-img create -f qcow2 -F qcow2 -b ./focal-server-cloudimg-amd64.img disk.img
    qemu-img resize disk.img +10G
    qemu-img rebase -f qcow2 -F qcow2 -b ./focal-server-cloudimg-amd64.img disk.img
fi

if [ ! -f user-data ]
then 
    sudo apt install cloud-init -y
    cat ./user-data.template | sed -e "s|<PUBLIC_KEY>|$(cat $PUBLIC_SSH_KEY)|g" > user-data
    cloud-init devel schema --config-file user-data
fi

if [ ! -f meta-data ]
then 
    cat ./meta-data.template  > meta-data
fi

if [ ! -f config.iso ]
then 
    genisoimage -o config.iso -V cidata -r -J user-data meta-data
fi

sudo apt install virt-manager -y

# If get "Permission denied" when open disk img
# https://github.com/jedi4ever/veewee/issues/996#issuecomment-555245785
sudo virt-install \
    --name maas-controller \
    --memory 4096 \
    --vcpus 2 \
    --os-variant ubuntu20.04 \
    --import \
    --disk path=./disk.img,bus=virtio,format=qcow2,cache=none,size=100 \
    --disk path=./config.iso,device=cdrom \
    --network bridge=virbr0 \
    --nographics
