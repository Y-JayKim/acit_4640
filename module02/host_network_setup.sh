#!/bin/bash -x
vbmg () { VBoxManage.exe "$@"; }
export PS4=' \[\e[0;34m(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\e[m\]'


# Create NatNetwork
vbmg natnetwork add --netname net_4640 --network "192.168.250.0/24" --enable --dhcp off
vbmg natnetwork modify --netname net_4640 --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80"
vbmg natnetwork modify --netname net_4640 --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"
vbmg natnetwork modify --netname net_4640 --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"

#Taking Virtual Machine name
echo Please type a hostname you would like to use:
read VM_NAME

vbmg createvm --name $VM_NAME --ostype "RedHat_64" --register
vbmg modifyvm $VM_NAME --cpus 1 --memory 1024 --nic1 natnetwork --nat-network1 net_4640 --mouse usbtablet --audio none

SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

#Creating VDI
vbmg createmedium disk --filename "$VM_DIR.vdi" --size 10000

#Add Sata Controller
vbmg storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAhci
vbmg storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR".vdi

#Add IDE controller for ISO
vbmg storagectl $VM_NAME --name "IDE Controller" --add ide --controller PIIX4
vbmg storageattach $VM_NAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium C:/Users/Jay/Downloads/CentOS-7-x86_64-Minimal-1810.iso
