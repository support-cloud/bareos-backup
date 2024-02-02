#!/bin/bash
#
# Authorship: XAASABLITY Product (Copyleft: all rights reversed).
# Tested by: Sahul Hameed (Sr.Devops Support Engineer)

# Log file path
log_file="/var/log/backup_cleanup.log"
# Function to log messages
log() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$log_file"
}
# Source the openrc file with the correct path
source /root/.openrc

# Get instance names
GET_INSTANCE_NAMES=$(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')

# Log the current date and time
log "Script started at $(date)" 

# Loop through instance names and delete directories if they exist
for instance_name in $GET_INSTANCE_NAMES; do
  backup_dir="/disk1/tmp/$instance_name"

# Check if the directory exists
  if [ -d "$backup_dir" ]; then
    rm -rf "$backup_dir"
    log "Deleted $backup_dir"
  fi
done
# Log the completion time
log "Script completed at $(date)" 
