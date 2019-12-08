#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - GlusterFS configuration operations                                                               #
# Usage : ./config.sh [--configure-cluster] [current_progress]                                                 #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Set array to declare bricks paths
declare -a BRICKS_PATHS
BRICKS_PATHS=( "${glusterfs_root}/wordpress-1" "${glusterfs_root}/wordpress-2" )

# Create folders to host the bricks of the GlusterFS volume for WordPress
for folder in "${BRICKS_PATHS[@]}"; do
    mkdir -p ${folder}
done

# Configure GlusterFS on last GlusterFS host provisioning (to be able to communicate to other hosts), detected with the --configure-cluster arg
if [ "${1}" == "--configure-cluster" ]; then
    bricks_arg=""
    bricks_count=0

    # Establish relation between hosts to create cluster and prepare args for the volume creation
    for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
        gluster peer probe ${glusterfs_hostname_base}${i}
        for brick in "${BRICKS_PATHS[@]}"; do
            bricks_arg+=" ${glusterfs_hostname_base}${i}:${brick}"
            ((bricks_count++))
        done
    done

    # Create the wordpress volume, start it and show info
    gluster volume create wordpress replica ${bricks_count} ${bricks_arg} force
    gluster volume start wordpress
    gluster volume info
fi

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0