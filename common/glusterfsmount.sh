#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# glusterfsmount.sh - Create a mountpoint for the wordpress volume at the root of the website                  #
# Usage : ./glusterfsmount.sh --apache|--nginx [current_progress]                                              #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Enpty the future mount point for the wordpress volume if it does not already contain a working WordPress install
[ "$(ls -A ${web_root})" ] && [ ! -f ${web_root}/wp-config.php ] && rm ${web_root}/*

# Mount the GlusterFS wordpress volume previously created
# Detect backup servers (for Nginx, the primary GlusterFS is set to be the first of the range)
backup_servers=""
master_server="${glusterfs_hostname_base}${glusterfs_ip_start}"           # Define master server to make the connection (first for Nginx or if there is just one GlusterFS server)

if [ ${glusterfs_ip_start} -ne ${glusterfs_ip_end} ]; then                # If there is more than one GlusterFS server
  if [ "${1}" == "--nginx" ]; then                                        # Nginx will use the servers from first to last
    for ((i=$((${glusterfs_ip_start}+1));i<=${glusterfs_ip_end};i++)); do # Loop through all the range, except for the first one
      backup_servers+="${glusterfs_hostname_base}${i}"                    # Add server name to backup servers
      [ ${i} -ne ${glusterfs_ip_end} ] && backup_servers+=":"             # If there is still servers to add, insert separator
    done
  elif [ "${1}" == "--apache" ]; then                                     # Apache will use the servers from last to first
    master_server="${glusterfs_hostname_base}${glusterfs_ip_end}"         # Define master server to make the connection
    for ((i=$((${glusterfs_ip_end}-1));i>=${glusterfs_ip_start};i--)); do # Loop through all the range, except for the last one
      backup_servers+="${glusterfs_hostname_base}${i}"                    # Add server name to backup servers
      [ ${i} -ne ${glusterfs_ip_start} ] && backup_servers+=":"           # If there is still servers to add, insert separator
    done
  fi
fi

# Add the volume to fstab, to mount automatically and make the mount persistent
if [ $(echo "${backup_servers}" | wc -c) -gt 1 ]; then
  fstab_mountpoint="${master_server}:/wordpress  ${web_root}  glusterfs defaults,_netdev,backup-volfile-servers=${backup_servers} 0 0" # GlusterFS client is used with backup servers
else
  fstab_mountpoint="${master_server}:/wordpress  ${web_root}  glusterfs defaults,_netdev 0 0"                                        # GlusterFS client is used without backup servers
fi
grep -qxF "${fstab_mountpoint}" /etc/fstab || echo "${fstab_mountpoint}" >> /etc/fstab  # Insert mountpoint in fstab if it does not exist yet

# Mount the web server root using fstab to use it in the current session, if it not already mounted
[ $(mount | grep "glusterfs" | grep "${web_root}" | wc -l) -eq 0 ] && mount ${web_root}
exit 0

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0