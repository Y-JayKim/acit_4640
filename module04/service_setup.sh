#!/bin/bash -x

export PS4=' \[\e[0;34m(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }\e[m\]'
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }
NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"

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
                    --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
                    --port-forward-4 "ssh_PXE:tcp:[]:50222:[192.168.250.200]:22" 
    echo "---------------NAT Network has been created."
}

#Create VM
CreateVM(){
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" \
                --cpus 1 --memory 2048 \
                --nic1 natnetwork \
                --nat-network1 "$NET_NAME" \
                --mouse usbtablet \
                --cableconnected1 on \
                --audio none \
                --boot1 disk \
                --boot2 net

    echo "---------------An empty VM has been created"
}

# Rest of VM Configuration
ConfigureVMSettings(){
    VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
    VM_DIR=$(dirname "$VBOX_FILE")
    
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
    
    echo "---------------VM configuration is completed"
}
#----------------------module-04--------------------
StartPXE()
{
    chmod 600 acit_admin_id_rsa
    if ! vbmg showvminfo $PXE_NAME | grep -c "running (since"
        then
            vbmg startvm $PXE_NAME
    fi

    while /bin/true; do
            ssh -i acit_admin_id_rsa -p 50222 -o ConnectTimeout=3s -o StrictHostKeyChecking=no -q admin@localhost exit
            if [ $? -ne 0 ]; then
                    echo "PXE server is not up, sleeping..."
                    sleep 3s
            else
                    break
            fi
    done
}

SetupAppVM(){
    #ssh -i acit_admin_id_rsa -p 50222 admin@localhost "sudo rm -rf /var/www/lighttpd/ks.cfg"
    scp -i acit_admin_id_rsa -P 50222  admin@localhost:/var/www/lighttpd/
    scp -i acit_admin_id_rsa -P 50222 acit_admin_id_rsa ks.cfg admin@localhost:/home/admin/
    ssh -i acit_admin_id_rsa -p 50222 admin@localhost "sudo mv /home/admin/ks.cfg /var/www/lighttpd/"
    ssh -i acit_admin_id_rsa -p 50222 admin@localhost "sudo chmod 755 /var/www/lighttpd/ks.cfg"
    
    vbmg startvm $VM_NAME
}



# Module 02
CleanAll
CreateNet
CreateVM
ConfigureVMSettings

# Module 04
StartPXE
SetupAppVM