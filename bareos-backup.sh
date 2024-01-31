#!/bin/bash
#
# Autorship:XAASABLITY Product  (Copyleft: all rights reversed).
# Tested by: Sahul Hameed (Sr.Devops Support Engineer)
# Source the openrc file with the correct path
source /root/.openrc
# Initialize an array to store VM names
vmnames=()

# Set the start and end index for VMs
start=0
end=2
# Get VM names
while IFS= read -r vm; do
    vmnames+=("$vm")
done < <(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')

for i in "${vmnames[@]:start:end}"; do
    
    # Get VM IDs for the instance
    vm_ids=($(nova --insecure list --all-tenants --status=Active | grep "$i" | awk '{print $2}'))
    # Create a directory for the VM backup
    backup_dir="/disk1/tmp/$i"
    
    if [[ ! -e "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi  

    for j in "${vm_ids[@]}"; do
        # Reset the array for each VM
        rbd_ids=()

        # Check if VM ID exists in Ceph RBD disks and continue to full backup
        while IFS= read -r line; do
            rbd_ids+=("$line")
        done < <(rbd ls -p vms | grep "$j"_disk)

        for ID in "${rbd_ids[@]}"; do
            if [ "$ID" == "$j"_disk ]; then
               rbd snap create vms/$ID@$ID ;
               rbd export --rbd-concurrent-management-ops 120 vms/$ID@$ID "$backup_dir/$ID.img" ;
               rbd snap rm vms/$ID@$ID
            fi
        done
    done
done
