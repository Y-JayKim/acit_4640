#!/bin/bash -x

export PS4=' \[\e[0;34m(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\e[m\]'
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
vbmg () { VBoxManage.exe "$@"; }
NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

#Delete NAT and VM
CleanAll(){
    vbmg natnetwork remove --netname "$NET_NAME"
    vbmg unregistervm "$VM_NAME" --delete 
}

# Create NatNetwork
CreateNet(){
    vbmg natnetwork add --netname "$NET_NAME" \
                    --network "192.168.250.0/24" \
                    --enable \
                    --dhcp off \
                    --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
                    --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
                    --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" 
    echo "---------------NAT Network has been created."
}

#Create VM
CreateVM(){
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" \
                --cpus 1 --memory 1024 \
                --nic1 natnetwork \
                --nat-network1 "$NET_NAME" \
                --mouse usbtablet \
                --audio none

    echo "---------------An empty VM has been created"
}

# Rest of VM Configuration
ConfigureVMSettings(){
    
    #Creating VDI
    vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi --size 10000

    #Add Sata Controller
    vbmg storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci

    vbmg storageattach "$VM_NAME" \
                --storagectl "SATA Controller" \
                --port 0 \
                --device 0 \
                --type hdd \
                --medium "$VM_DIR"/"$VM_NAME".vdi

    #Add IDE controller for ISO
    vbmg storagectl "$VM_NAME" --name "IDE Controller" --add ide --controller PIIX4
    
    vbmg storageattach "$VM_NAME" \
                --storagectl "IDE Controller" \
                --port 1 \
                --device 0 \
                --type dvddrive\
                --medium C:/Users/Jay/Downloads/CentOS-7-x86_64-Minimal-1810.iso
    
    echo "---------------VM configuration is completed"
}

CleanAll
CreateNet
CreateVM
ConfigureVMSettings


