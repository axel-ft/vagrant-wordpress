#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - MariaDB configuration operations                                                                 #
# Usage : ./config.sh  [current_progress]                                                                      #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Authorize external connections by binding to 0.0.0.0 instead of 127.0.0.1
sed -i.bak -e "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# Secure mariadb installation (direct queries equivalent to mysql_secure_installation)
mysql -e "UPDATE mysql.user SET Password=PASSWORD('${database_root_password}') WHERE User='root';"      # Define root password
mysql -e "DELETE FROM mysql.user WHERE User='';"                                                        # Remove anonymous users
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"  # Remove remote access for root
mysql -e "DROP DATABASE IF EXISTS test;"                                                                # Drop test database
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"                                        # Drop test database information
mysql -e "FLUSH PRIVILEGES;"                                                                            # Reload privileges

# Create WordPress Database and users for each web server
mysql -e "CREATE DATABASE IF NOT EXISTS ${database_name} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    mysql -e "GRANT ALL ON ${database_name}.* TO '${database_username}'@'${range_ip_base}${i}' IDENTIFIED BY '${database_user_password}';"
done
for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    mysql -e "GRANT ALL ON ${database_name}.* TO '${database_username}'@'${range_ip_base}${i}' IDENTIFIED BY '${database_user_password}';"
done
mysql -e "FLUSH PRIVILEGES;"

# Restart mariadb to bind with 0.0.0.0
systemctl restart mariadb

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0