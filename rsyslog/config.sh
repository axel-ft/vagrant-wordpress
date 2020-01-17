#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - Rsyslog configuration operations                                                                   #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Create dir to receive logs
mkdir -p /srv/rsyslog
chgrp syslog /srv/rsyslog
chmod g+w -R /srv/rsyslog

NAME_LIST="${squid_hostname}, ${haproxy_hostname}, ${mariadb_hostname}, ${rsyslog_hostname}, ${elk_hostname}, ${centreon_hostname}"
for ((i=${glusterfs_ip_start};i<=${glusterfs_ip_end};i++)); do
    NAME_LIST+=", ${glusterfs_hostname_base}${i}"
done
for ((i=${nginx_ip_start};i<=${nginx_ip_end};i++)); do
    NAME_LIST+=", ${nginx_hostname_base}${i}"
done
for ((i=${apache_ip_start};i<=${apache_ip_end};i++)); do
    NAME_LIST+=", ${apache_hostname_base}${i}"
done

# Activate server mode for rsyslog
sed -i.orig -e 's/^#module(load="imudp")$/module(load="imudp")/' \
            -e 's/^#input(type="imudp" port="514")$/input(type="imudp" port="514")/' \
            -e 's/^#module(load="imtcp")$/module(load="imtcp")/' \
            -e 's/^#input(type="imtcp" port="514")$/input(type="imtcp" port="514")/' /etc/rsyslog.conf

# Write Allowed sender variables with all our hosts
grep -qxF "\$AllowedSender UDP, ${NAME_LIST}" /etc/rsyslog.conf || sed -i.bak -e "/input(type=\"imudp\" port=\"514\")/a \
\$AllowedSender UDP, ${NAME_LIST}" /etc/rsyslog.conf
grep -qxF "\$AllowedSender TCP, ${NAME_LIST}" /etc/rsyslog.conf || sed -i -e "/input(type=\"imtcp\" port=\"514\")/a \
\$AllowedSender TCP, ${NAME_LIST}" /etc/rsyslog.conf

# Add template to receive remote logs
grep -qF 'template remote-logs' /etc/rsyslog.conf || sed -i -e "N;/###########################\n#### GLOBAL DIRECTIVES ####/i \
\$PreserveFQDN on\n\n\$template remote-logs,\"/srv/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log\"\n*.* ?remote-logs\n" /etc/rsyslog.conf

# Restarting rsyslog to apply changes, if configuration is correct
rsyslogd -N1 && systemctl restart rsyslog


# Disable Filebeat output to Elastic (use Logstash instead)
sed -i.bak -e 's/^output.elasticsearch:$/#output.elasticsearch:/' \
-e 's/^  hosts: \["localhost:9200"\]$/  #hosts: ["localhost:9200"]/' \
-e 's/^#output.logstash:$/output.logstash:/' \
-e "s/^  #hosts: \[\"localhost:5044\"\]$/  hosts: [\"${elk_hostname}:5044\"]/" /etc/filebeat/filebeat.yml

# Install squid module
cd /tmp && wget --progress=bar:force https://github.com/molu8bits/squid-filebeat-kibana/archive/master.zip
unzip -q master.zip
mv /tmp/squid-filebeat-kibana-master/filebeat/module/squid /usr/share/filebeat/module
mv /tmp/squid-filebeat-kibana-master/filebeat/etc/filebeat/modules.d/squid.yml.disabled /etc/filebeat/modules.d/squid.yml.disabled

cat << 'FIELDS' >> /etc/filebeat/fields.yml
- key: squid
  title: "squid"
  description: >
    squid Module
  fields:
    - name: squid
      type: group
      description: >
      fields:
        - name: access
          description: Please add description
          example: Please add example
          type: group
          fields:
          - name: response_time
            description: Response Time.
            example: 823
            type: long
          - name: src_ip
            description: Source request IP
          - name: squid_request_status
            description: TAG_NONE
            type: keyword
          - name: http_status_code
            description: HTTP Status Code
            example: 200
            type: long
          - name: reply_size_include_header
            description: Reply size including header.
            example: 10940
            type: long
          - name: http_method
            description: The request HTTP method.
            example: GET
            type: keyword
          - name: http_protocol
            description: HTTP Protocol
            example: http
            type: keyword
          - name: dst_host
            description: Destination host
            example: github.com
            type: keyword
          - name: request_url
            description: The requested HTTP URL.
            example: http://github.com/molu8bits
          - name: user
            description: Squid username
            example: bombelek500plus
          - name: hierarchy_code
            description: Hierarchy Code
            example: ORIGINAL_DST
            type: keyword
          - name: dst_ip
            description: Destination IP address
            example: 192.168.0.1
          - name: content_type
            description:  Content Type
            example: application/octet-stream
          - name: request_url_port
            description: Request url port
            example: 34052
            type: long
          - name: geoip
            type: group
            fields:
              - name: continent_name
                type: alias
                path: squid.access.geoip.continent_name
                migration: true
              - name: country_iso_code
                type: alias
                path: squid.access.geoip.country_iso_code
                migration: true
              - name: location
                type: geo_point
                path: squid.access.geoip.location
                migration: true
              - name: region_name
                type: alias
                path: squid.access.geoip.region_name
                migration: true
              - name: city_name
                type: alias
                path: squid.access.geoip.city_name
                migration: true
              - name: region_iso_code
                type: alias
                path: squid.access.geoip.region_iso_code
                migration: true
FIELDS

# Enable and configure filebeat system module
filebeat modules enable system
sed -i.bak -e '5,12s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/syslog*"]/' -e '13,19s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/useradd.log*", "\/srv\/rsyslog\/*\/userdel.log*", "\/srv\/rsyslog\/*\/su.log*", "\/srv\/rsyslog\/*\/sshd.log*", "\/srv\/rsyslog\/*\/sudo.log*", "\/srv\/rsyslog\/*\/polkitd(authority=local).log*", "\/srv\/rsyslog\/*\/CRON.log*"]/' /etc/filebeat/modules.d/system.yml

# Enable and configure filebeat squid module
filebeat modules enable squid
sed -i.bak -e 's/^    var.paths: \["\/var\/log\/squid\/access.log"\]$/    var.paths: ["\/srv\/rsyslog\/*\/(squid-1).log*"]/' /etc/filebeat/modules.d/squid.yml

# Enable and configure filebeat haproxy module
filebeat modules enable haproxy
sed -i.bak -e 's/^    #var.input:$/    var.input: file/' -e 's/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/haproxy.log*"]/' /etc/filebeat/modules.d/haproxy.yml

# Enable and configure filebeat nginx module
filebeat modules enable nginx
sed -i.bak -e '5,12s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/nginx_wp_access.log*"]/' -e '13,19s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/nginx_wp_error.log*"]/' /etc/filebeat/modules.d/nginx.yml

# Enable and configure filebeat apache module
filebeat modules enable apache
sed -i.bak -e '5,12s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/apache_wp_access.log*"]/' -e '13,19s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/apache_wp_error.log*"]/' /etc/filebeat/modules.d/apache.yml

# Enable and configure filebeat mysql module
filebeat modules enable mysql
sed -i.bak -e '5,12s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/mariadb_wp_error.log*"]/' -e '13,19s/^    #var.paths:$/    var.paths: ["\/srv\/rsyslog\/*\/mariadb_wp_slow.log*"]/' /etc/filebeat/modules.d/mysql.yml

# Create elasticsearch index
filebeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"${elk_hostname}:9200\"]" -E output.elasticsearch.proxy_disable

# Test and restart logstash
filebeat test config -e && systemctl restart filebeat

# Delete old data in elastic if it exists with any previous template
curl -X DELETE "http://${elk_hostname}:9200/filebeat-*" --noproxy '*' 1> /dev/null

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0