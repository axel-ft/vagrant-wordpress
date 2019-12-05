#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Nginx configuration operations for HTTP                                                          #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Remove existing default file if it is enabled in nginx
[ -f /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default

# Write configuration file for the vhost. It is only HTTPS and uses the cert placed in the cert folder, generated by Let's Encrypt CA.
cat << NGINX > /etc/nginx/sites-available/wordpress.conf
upstream php {
  server unix:/run/php/php7.2-fpm.sock;
}

server {
  listen [::]:80 default_server;
  listen 80 default_server;     
  server_name ${domain_name};
  root ${web_root};
  index index.php;

  access_log /var/log/nginx/${domain_name}-access.log;
  error_log /var/log/nginx/${domain_name}-error.log;

  location = /favicon.ico {
    log_not_found off;
    access_log off;
  }

  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
    include fastcgi.conf;
    fastcgi_intercept_errors on;
    fastcgi_pass php;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
    expires max;
    log_not_found off;
  }
}
NGINX

# Enable site and restart nginx
ln -sf /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/wordpress.conf
nginx -t && systemctl restart nginx

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0