#!/bin/bash

################################################################################################################
#       /!\ Make sure to include the vm_params as environment for correct execution of this script /!\         #
# config.sh - ELK configuration operations                                                                   #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# Creating and mounting swap to prevent filling all the memory
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 0600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile                      none            swap    sw              0       0" >> /etc/fstab
fi

# Make Elastic bind on all interfaces, and other config
cat << 'ELASTICSEARCH' > /etc/elasticsearch/elasticsearch.yml
cluster.name: wordpress
node.name: elastic19
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
#http.port: 9200
discovery.zen.minimum_master_nodes: 1
discovery.zen.ping.unicast.hosts: ["localhost"]
gateway.recover_after_nodes: 1
gateway.expected_nodes: 1
gateway.recover_after_time: 5m
ELASTICSEARCH

# Make Kibana listen on all interfaces (iptables then restricts to localhost and HAProxy)
sed -i.bak -e 's/^#server.host: "localhost"$/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml

# Define Logstash input
cat << 'LOGSTASH' > /etc/logstash/conf.d/02-beats-input.conf
input {
  beats {
    port => 5044
  }
}
LOGSTASH

# Define System filter
cat << 'LOGSTASH' > /etc/logstash/conf.d/10-syslog-filter.conf
filter {
  if [event][module] == "system" {
    if [fileset][name] == "auth" {
      grok {
        match => { "message" => ["%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} %{WORD}(?:\[%{POSINT:[system][auth][pid]}\])?: (?=%{GREEDYDATA:message})%{WORD:[system][auth][pam_module]}\(%{DATA:[system][auth][pam_caller]}\): session %{WORD:[system][auth][pam_session_state]} for user %{USERNAME:[system][auth][username]}(?: by %{GREEDYDATA:[system][auth][pam_by]})?",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} %{DATA:[system][auth][ssh][method]} for (invalid user )?%{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]} port %{NUMBER:[system][auth][ssh][port]} ssh2(: %{GREEDYDATA:[system][auth][ssh][signature]})?",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} user %{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]}",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: Did not receive identification string from %{IPORHOST:[system][auth][ssh][dropped_ip]}",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sudo(?:\[%{POSINT:[system][auth][pid]}\])?: \s*%{DATA:[system][auth][user]} :( %{DATA:[system][auth][sudo][error]} ;)? TTY=%{DATA:[system][auth][sudo][tty]} ; PWD=%{DATA:[system][auth][sudo][pwd]} ; USER=%{DATA:[system][auth][sudo][user]} ; COMMAND=%{GREEDYDATA:[system][auth][sudo][command]}",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} groupadd(?:\[%{POSINT:[system][auth][pid]}\])?: new group: name=%{DATA:system.auth.groupadd.name}, GID=%{NUMBER:system.auth.groupadd.gid}",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} useradd(?:\[%{POSINT:[system][auth][pid]}\])?: new user: name=%{DATA:[system][auth][user][add][name]}, UID=%{NUMBER:[system][auth][user][add][uid]}, GID=%{NUMBER:[system][auth][user][add][gid]}, home=%{DATA:[system][auth][user][add][home]}, shell=%{DATA:[system][auth][user][add][shell]}$",
          "%{TIMESTAMP_ISO8601:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} %{DATA:[system][auth][program]}(?:\[%{POSINT:[system][auth][pid]}\])?: %{GREEDYMULTILINE:[system][auth][message]}"] }
        pattern_definitions => {
          "GREEDYMULTILINE"=> "(.|\n)*"
        }
        remove_field => "message"
      }
      date {
        match => [ "[system][auth][timestamp]", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss", "ISO8601" ]
      }
      geoip {
        source => "[system][auth][ssh][ip]"
        target => "[system][auth][ssh][geoip]"
      }
    }
    else if [fileset][name] == "syslog" {
      grok {
        match => { "message" => ["%{TIMESTAMP_ISO8601:[system][syslog][timestamp]} %{SYSLOGHOST:[system][syslog][hostname]} %{DATA:[system][syslog][program]}(?:\[%{POSINT:[system][syslog][pid]}\])?: %{GREEDYMULTILINE:[system][syslog][message]}"] }
        pattern_definitions => { "GREEDYMULTILINE" => "(.|\n)*" }
        remove_field => "message"
      }
      date {
        match => [ "[system][syslog][timestamp]", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
      }
    }
  }
}
LOGSTASH

# Define Squid filter
cat << 'LOGSTASH' > /etc/logstash/conf.d/11-squid-filter.conf
filter {
  if [event][module] == "squid" {
    if [fileset][name] == "access" {
      grok {
        match => { "message" => "%{TIMESTAMP_ISO8601:[squid][syslog][timestamp]} %{SYSLOGHOST:[squid][hostname]} \(squid-1\)(?:\[%{POSINT:[squid][pid]}\])?: %{NUMBER:[squid][timestamp]}\s+%{NUMBER:[squid][duration]}\s%{IP:[squid][client_address]}\s%{WORD:[squid][cache_result]}/%{POSINT:[squid][status_code]}\s%{NUMBER:[squid][bytes]}\s%{WORD:[squid][request_method]}\s%{NOTSPACE:[squid][url]}\s(%{NOTSPACE:[squid][user]}|-)\s%{WORD:[squid][hierarchy_code]}/(%{IPORHOST:[squid][server]}|-)\s%{NOTSPACE:[squid][content_type]}" }
        remove_field => "message"
      }    
      geoip {
        source => "clientip"
      }
    }
  }
}
LOGSTASH

# Define HAProxy filter
cat << 'LOGSTASH' > /etc/logstash/conf.d/12-haproxy-filter.conf
filter {
  if [event][module] == "haproxy" {
    if [fileset][name] == "log" {
      grok {
        match => { "message" => "%{HAPROXYHTTP}" }
        remove_field => "message"
      }
    }
  }
}
LOGSTASH

# Define Nginx filter
cat << 'LOGSTASH' > /etc/logstash/conf.d/13-nginx-filter.conf
filter {
  if [event][module] == "nginx" {
    if [fileset][name] == "access" {
      grok {
        match => { "message" => ["%{IPORHOST:[nginx][access][remote_ip]} - %{DATA:[nginx][access][user_name]} \[%{HTTPDATE:[nginx][access][time]}\] \"%{WORD:[nginx][access][method]} %{DATA:[nginx][access][url]} HTTP/%{NUMBER:[nginx][access][http_version]}\" %{NUMBER:[nginx][access][response_code]} %{NUMBER:[nginx][access][body_sent][bytes]} \"%{DATA:[nginx][access][referrer]}\" \"%{DATA:[nginx][access][agent]}\""] }
        remove_field => "message"
      }
      mutate {
        add_field => { "read_timestamp" => "%{@timestamp}" }
      }
      date {
        match => [ "[nginx][access][time]", "dd/MMM/YYYY:H:m:s Z" ]
        remove_field => "[nginx][access][time]"
      }
      useragent {
        source => "[nginx][access][agent]"
        target => "[nginx][access][user_agent]"
        remove_field => "[nginx][access][agent]"
      }
      geoip {
        source => "[nginx][access][remote_ip]"
        target => "[nginx][access][geoip]"
      }
    }
  }
}
LOGSTASH

# Define Apache filter
cat << LOGSTASH > /etc/logstash/conf.d/14-apache-filter.conf
filter {
  if [event][module] == "apache" {
    if [fileset][name] == "access" {
      grok {
        match => { "message" => "%{COMBINEDAPACHELOG}" }
        remove_field => "message"
      }    
      geoip {
        source => "clientip"
      }
    }
  }
}
LOGSTASH

cat << 'LOGSTASH' > /etc/logstash/conf.d/15-mariadb-filter.conf
filter {
 if [event][module] == "mysql" {
    if [fileset][name] == "error" {
      grok {
        match => { "message" => ["%{LOCALDATETIME:[mysql][error][timestamp]} (\[%{DATA:[mysql][error][level]}\] )?%{GREEDYDATA:[mysql][error][message]}",
          "%{TIMESTAMP_ISO8601:[mysql][error][timestamp]} %{NUMBER:[mysql][error][thread_id]} \[%{DATA:[mysql][error][level]}\] %{GREEDYDATA:[mysql][error][message1]}",
          "%{GREEDYDATA:[mysql][error][message2]}"] }
        pattern_definitions => {
          "LOCALDATETIME" => "[0-9]+ %{TIME}"
        }
        remove_field => "message"
      }
      mutate {
        rename => { "[mysql][error][message1]" => "[mysql][error][message]" }
      }
      mutate {
        rename => { "[mysql][error][message2]" => "[mysql][error][message]" }
      }
      date {
        match => [ "[mysql][error][timestamp]", "ISO8601", "YYMMdd H:m:s" ]
        remove_field => "[mysql][error][time]"
      }
    }
    else if [fileset][name] == "slowlog" {
      grok {
        match => { "message" => ["^# User@Host: %{USER:[mysql][slowlog][user]}(\[[^\]]+\])? @ %{HOSTNAME:[mysql][slowlog][host]} \[(IP:[mysql][slowlog][ip])?\](\s*Id:\s* %{NUMBER:[mysql][slowlog][id]})?\n# Query_time: %{NUMBER:[mysql][slowlog][query_time][sec]}\s* Lock_time: %{NUMBER:[mysql][slowlog][lock_time][sec]}\s* Rows_sent: %{NUMBER:[mysql][slowlog][rows_sent]}\s* Rows_examined: %{NUMBER:[mysql][slowlog][rows_examined]}\n(SET timestamp=%{NUMBER:[mysql][slowlog][timestamp]};\n)?%{GREEDYMULTILINE:[mysql][slowlog][query]}"] }
        pattern_definitions => {
          "GREEDYMULTILINE" => "(.|\n)*"
        }
        remove_field => "message"
      }
      date {
        match => [ "[mysql][slowlog][timestamp]", "UNIX" ]
      }
      mutate {
        gsub => ["[mysql][slowlog][query]", "\n# Time: [0-9]+ [0-9][0-9]:[0-9][0-9]:[0-9][0-9](\\.[0-9]+)?$", ""]
      }
    }
  }
}
LOGSTASH

# Define Logstash output
cat << 'LOGSTASH' > /etc/logstash/conf.d/30-elasticsearch-output.conf
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
LOGSTASH

# Change elasticsearch start timeout to prevent failures
mkdir -p /etc/systemd/system/elasticsearch.service.d
cat << 'SYSTEMD' > /etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
TimeoutStartSec=3min
SYSTEMD
systemctl daemon-reload

# Restart all ELK services if their config is correct, if available
systemctl restart elasticsearch
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t && systemctl restart logstash
systemctl restart kibana

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0