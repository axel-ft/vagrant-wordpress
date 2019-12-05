#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# getwordpress.sh - Gets and extracts latest WordPress to the web root, and configures database if possible    #
# Usage : ./getwordpress.sh http|https [current_progress]                                                      #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Download WordPress and extract it to root web server if there is no working WordPress install yet
if [ ! -f ${web_root}/wp-config.php ]; then
  # Clean any existing download
  [ -f /tmp/latest-fr_FR.zip ] && rm -f /tmp/latest-fr_FR.zip
  [ -d /tmp/wordpress ] && rm -rf /tmp/wordpress

  # Do the actual download and extraction
  cd /tmp && wget --progress=bar:force https://fr.wordpress.org/latest-fr_FR.zip
  unzip -q latest-fr_FR.zip
  mv -f /tmp/wordpress/* ${web_root}
fi

# Request to create new wordpress config and save it to file if it doesn't exist yet
if [ ! -f ${web_root}/wp-config.php ]; then
  pwd=$(php -r "echo urlencode('${database_user_password}');") # URL encode the password which contains special chars. We know that php is present on the web servers and take advantage of that.
  curl --noproxy '*' -s -d "dbname=${database_name}&uname=${database_username}&pwd=${pwd}&dbhost=${mariadb_hostname}&prefix=${website_prefix}&language=fr_FR&submit=Envoyer" -X POST ${1}://${domain_name}/wp-admin/setup-config.php?step=2 | sed '1,/textarea/d;/textarea/,$d;w /tmp/wp-config.php' 1>/dev/null

  # If file has been created and is not empty, add php header, remove CR, reencode to UTF-8 and move it to the web root
  if [ -f /tmp/wp-config.php ] && [ $(wc -l /tmp/wp-config.php | cut -b 1) -gt 0 ]; then
    sed -i -e '1s/^/<?php\n/' /tmp/wp-config.php 1>/dev/null && sed -i -e 's/\r//g' /tmp/wp-config.php 1>/dev/null && recode HTML..UTF-8 wp-config.php && mv /tmp/wp-config.php ${web_root}/wp-config.php
    echo 'WordPress configuration file successfully saved !'

    # If file has successfully been saved, configure website parameters if all values are present
    if [ $(echo "${website_name}" | wc -c) -gt 1 ] && [ $(echo "${website_username}" | wc -c) -gt 1 ] && [ $(echo "${website_password}" | wc -c) -gt 1 ] && [ $(echo "${website_email}" | wc -c) -gt 1 ]; then
      # URL encode parameters that may contain special chars
      weblog_title=$(php -r "echo urlencode('${website_name}');")
      admin_password=$(php -r "echo urlencode('${website_password}');")
      admin_email=$(php -r "echo urlencode('${website_email}');")

      # Send them to the website
      curl --noproxy '*' -s -d "weblog_title=${weblog_title}&user_name=${website_username}&admin_password=${admin_password}&admin_password2=${admin_password}&admin_email=${admin_email}&blog_public=${noindex}&Submit=Installer+WordPress&language=" -X POST ${1}://${domain_name}/wp-admin/install.php?step=2 1>/dev/null
      
      # Print message about the server response
      if [ ${?} -eq 0 ]; then
        echo 'Website successfully configured !'
      else
        echo 'Configuration of the website was impossible'
      fi
    else
      echo 'Parameters empty, leaving the website install with GUI'
    fi
  else
    echo 'Unable to configure database for Wordpress, will be prompted on first connection'
  fi
fi

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${2} ] && progressbar ${2}
exit 0
