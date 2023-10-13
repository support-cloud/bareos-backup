#!/bin/bash
#
# Autorship:XAASABLITY Product  (Copyleft: all rights reversed).
# Tested by: Sahul Hameed (Sr.Devops Support Engineer)
# Source the openrc file with the correct path
source /root/.openrc

# Log file location
log_file="/var/log/backup_cleanup.log"

# Get instance names
GET_INSTANCE_NAMES=$(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')

# Log the current date and time
echo "Script started at $(date)" >> "$log_file"

# Loop through instance names and delete directories if they exist
for instance_name in $GET_INSTANCE_NAMES; do
  backup_dir="/disk1/tmp/$instance_name"

# Check if the directory exists
  if [ -d "$backup_dir" ]; then
    rm -rf "$backup_dir"
    echo "Deleted $backup_dir" >> "$log_file"
  fi
done

# Log the completion time
echo "Script completed at $(date)" >> "$log_file"
