#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Apache 2 configuration operations for HTTP                                                       #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Remove existing default file if it is enabled in apache
[ -f /etc/apache2/sites-enabled/000-default.conf ] && rm /etc/apache2/sites-enabled/000-default.conf

# Enable modules used in configuration
# proxy_fcgi is used to interact with php7.2-fpm
a2enmod proxy_fcgi

# Write configuration file
grep -qF "ServerName" /etc/apache2/apache2.conf || sed -i.bak -e "70s/^/ServerName ${domain_name}\\n/" /etc/apache2/apache2.conf 1>/dev/null
cat << APACHE > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
  ServerName ${domain_name}
  Protocols http:/1.1

  DirectoryIndex index.php index.html
  DocumentRoot ${web_root}

  ErrorLog \${APACHE_LOG_DIR}/${domain_name}-error.log
  CustomLog \${APACHE_LOG_DIR}/${domain_name}-access.log combined

  <FilesMatch "/\$|.php\$">
    SetHandler "proxy:unix:/var/run/php/php7.2-fpm.sock|fcgi://localhost/"
  </FilesMatch>

  <Directory ${web_root}>
      Options FollowSymLinks
      Options -Indexes
      AllowOverride All
      Require all granted
  </Directory>

</VirtualHost>
APACHE

# Enable site and restart apache
a2ensite wordpress
apache2ctl configtest && systemctl restart apache2

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0