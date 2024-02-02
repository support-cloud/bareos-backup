#!/bin/bash
#
# Authorship: XAASABLITY Product (Copyleft: all rights reversed).
# Tested by: Sahul Hameed (Sr.Devops Support Engineer)
# Log file path
log_file="/var/log/volume-scripts.log"
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
start=0
end=10
# Get VM names
while IFS= read -r vm; do
    vmnames+=("$vm")
done < <(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')
# Loop through VMs
for vm in "${vmnames[@]:start:end}"; do
    if [ -z "$vm" ]; then
      log "VM name null value returned. Exiting loop."
      break
    fi
    log "Processing VM: $vm"
    volcount=$(openstack server show "$vm" -f json -c volumes_attached | jq -r '.volumes_attached | length')

    if [ -n "$volcount" ] && [ "$volcount" -ge 1 ]; then
       for vol in $(openstack server show "$vm" -f json -c volumes_attached | jq -r '.volumes_attached[].id'); do
          volcount=$((volcount-1))
          # Create a directory for the VM backup
          backup_dir="/disk1/tmp/$vm"
          if [[ ! -e "$backup_dir" ]]; then
            mkdir -p "$backup_dir"
          fi
          log "Backup directory created: $backup_dir"
          rbd_ids=($(rbd ls -p volumes | grep volume-"$vol"))
          for rbd_id in "${rbd_ids[@]}"; do
             if [ "$rbd_id" == volume-"$vol" ]; then
               log "Processing volume RBD ID: $rbd_id"
               # Check if snapshot already exists
               if rbd info volumes/$rbd_id@${vol} &> /dev/null; then
                  log "Volume snapshot already exists ${vol}. Exporting..."
                  rbd export --rbd-concurrent-management-ops 120 volumes/$rbd_id@${vol} "$backup_dir/${vol}.img"
                  rbd snap rm volumes/$rbd_id@${vol}
               else
                  log "Volume snapshot doesn't exist. Creating..."
                  rbd snap create volumes/$rbd_id@${vol}
                  log "Volume snapshot created. Exporting..."
                  rbd export --rbd-concurrent-management-ops 120 volumes/$rbd_id@${vol} "$backup_dir/${vol}.img"
                  log "Export completed. Removing..."
                  rbd snap rm volumes/$rbd_id@${vol}
               fi
             fi
          done
       done
    fi
done
log "Volume Backup Script execution completed."
