#!/bin/bash
#
# Authorship: XAASABLITY Product (Copyleft: all rights reversed).
# Tested by: Sahul Hameed (Sr.Devops Support Engineer)

# Log file path
log_file="/var/log/scripts.log"

# Function to log messages
log() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$log_file"
}

# Source the openrc file with the correct path
source /root/.openrc

# Initialize an array to store VM names
vmnames=()

# Set the start and end index for VMs
start=0
end=3

# Get VM names
while IFS= read -r vm; do
    vmnames+=("$vm")
done < <(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')

# Loop through VMs
for vm in "${vmnames[@]:start:end}"; do
    log "Processing VM: $vm"

    # Get VM IDs for the instance
    vm_ids=($(nova --insecure list --all-tenants | grep "$vm" | awk '{print $2}'))

    # Create a directory for the VM backup
    backup_dir="/disk1/tmp/$vm"
    mkdir -p "$backup_dir"
    log "Backup directory created: $backup_dir"

    # Loop through VM IDs
    for vm_id in "${vm_ids[@]}"; do
        log "Processing VM ID: $vm_id"

        # Get RBD IDs for the VM ID
        rbd_ids=($(rbd ls -p vms | grep "${vm_id}_disk"))

        # Loop through RBD IDs
        for rbd_id in "${rbd_ids[@]}"; do
            if [ "$rbd_id" == "${vm_id}_disk" ]; then
                log "Processing RBD ID: $rbd_id"

                # Check if snapshot already exists
                if rbd info vms/$rbd_id@${vm_id} &> /dev/null; then
                    log "Snapshot already exists. Exporting..."
                    rbd export --rbd-concurrent-management-ops 120 vms/$rbd_id@${vm_id} "$backup_dir/${vm_id}.img"
                    rbd snap rm vms/$rbd_id@${vm_id}
                else
                    log "Snapshot doesn't exist. Creating..."
                    rbd snap create vms/$rbd_id@${vm_id}
                    rbd export --rbd-concurrent-management-ops 120 vms/$rbd_id@${vm_id} "$backup_dir/${vm_id}.img"
                    rbd snap rm vms/$rbd_id@${vm_id}
                fi
            fi
        done
    done
done
log "Script execution completed."
