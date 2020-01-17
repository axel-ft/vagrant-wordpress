#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - HAProxy configuration operations for HTTP                                                        #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Exit if conf is already provisioned to prevent doubling the file content
if [ -f /etc/haproxy/haproxy.lock ]; then echo "!!!!! Configuration file has already been provisioned. Aborting this script to prevent double data in file !!!!!"; exit 0; fi;

# Log requests with errors in a separate file
echo -e "\toption log-separate-errors" >> /etc/haproxy/haproxy.cfg

# Appending the frontend, backend and stats config
cat << HAPROXY >> /etc/haproxy/haproxy.cfg

frontend http-in
        bind *:80
        acl wp-front hdr(host) -i ${domain_name}
        acl kibana-front hdr(host) -i ${kibana_domain_name}
        acl centreon-front hdr(host) -i ${centreon_domain_name}
        acl cockpit-front hdr(host) -i ${cockpit_domain_name}
        reqadd X-Forwarded-Proto:\\ http
        mode http
        option http-server-close
        option forwardfor
        use_backend wp-back if wp-front
        use_backend kibana-back if kibana-front
        use_backend centreon-back if centreon-front
        use_backend cockpit-back if cockpit-front
        default_backend wp-back
  
backend wp-back    
        mode http
        balance roundrobin
        cookie serverid insert indirect nocache
        option forwardfor
HAPROXY

# Append all Nginx servers
for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    echo "$(printf '\t')server web$(printf "%02d" ${i}) ${nginx_hostname_base}$(printf "%02d" ${i}):80 check cookie web$(printf "%02d" ${i})" >> /etc/haproxy/haproxy.cfg
done

# Append all Apache servers
for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    echo "$(printf '\t')server web$(printf "%02d" ${i}) ${apache_hostname_base}$(printf "%02d" ${i}):80 check cookie web$(printf "%02d" ${i})" >> /etc/haproxy/haproxy.cfg
done

cat << HAPROXY >> /etc/haproxy/haproxy.cfg
        http-request set-header X-Forwarded-Port %[dst_port]
        http-request add-header X-Forwarded-Proto http

backend kibana-back
        mode http
        option forwardfor
        server kibana ${elk_hostname}:5601 check
        http-request set-header X-Forwarded-Port %[dst_port]
        http-request add-header X-Forwarded-Proto http
        
backend centreon-back
        mode http
        option forwardfor
        server centreon ${centreon_hostname}:80 check
        http-request set-header X-Forwarded-Port %[dst_port]
        http-request add-header X-Forwarded-Proto https if { ssl_fc }

backend cockpit-back
        mode http
        option forwardfor
        server cockpit ${cockpit_hostname}:9090 check
        http-request set-header X-Forwarded-Port %[dst_port]
        http-request add-header X-Forwarded-Proto https if { ssl_fc }
  
listen stats
        bind *:1936
        stats enable
        stats uri /
        stats hide-version
        stats auth ${haproxy_stats_user}:${haproxy_stats_password}
HAPROXY

# Creating a lock file to avoid reprovisioning this config
echo 'DO NOT TOUCH!\\nKeep this file here to avoid redeploying the config for HAProxy in the same file, doubling the data as the text is appended' > /etc/haproxy/haproxy.lock
chmod 0400 /etc/haproxy/haproxy.lock

# Restarting HAProxy to apply changes, if configuration is correct
haproxy -f /etc/haproxy/haproxy.cfg -c && systemctl restart haproxy

# Preventing stop for log file in default rsyslog haproxy conf
sed -i.bak -e 's/^&~$//' /etc/rsyslog.d/49-haproxy.conf

# Restarting rsyslog to apply changes, if configuration is correct
rsyslogd -N1 && systemctl restart rsyslog

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0