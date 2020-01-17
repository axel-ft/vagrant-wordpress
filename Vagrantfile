# -*- mode: ruby -*-
# vi: set ft=ruby :

############################################################################################################################################
# Deploying 10 VM with Vagrant : 1 proxy, 1 reverse proxy, 3 web servers (wordpress), 2 file servers, a database server and two log server #
# This script uses a folder called cert placed aside this file, which contains all the files generated by Let's Encrypt for HTTPS serving  #
#                                                      Author: Axel Floquet-Trillot                                                        #
############################################################################################################################################

Vagrant.configure("2") do |config|
  # Checking, and maybe installing vagrant-env plugin if it is not present to retrieve passwords from .env file
  puts "Installing missing plugin vagrant-env..."
  config.vagrant.plugins = "vagrant-env"

  # Check updates and use use Ubuntu 18.04 image from Hashicorp
  config.vm.box = "hashicorp/bionic64"
  config.vm.box_check_update = true

  # Use the .env file to load passwords
  config.env.enable
  config.vagrant.sensitive = [ENV['HAPROXY_STATS_PASSWORD'], ENV['DB_ROOT_PASSWORD'], ENV['DB_USER_PASSWORD'], ENV['WP_ADMIN_PASSWORD']]

  # Define all variables here in a flat hash (nested hash cannot be used easily in provision)
  # All params are transmitted to scripts with environment variables
  vm_params = {
    # Network configuration
    :range_ip_base           => "192.168.43.",                      # Cannot be wider than a 255.255.255.0 network (scripts won't work)
    :netmask                 => "255.255.255.0",                    # Cannot be wider that a 255.255.255.0 network (scripts won't work)
    :bridgeif                => "Intel(R) Wireless-AC 9560 160MHz", # Name of the interface to bridge. Command "VBoxManage list bridgedifs" is used to obtain the correct name
    :bridgeif_guest_name     => "eth1",                             # Name of the bridged interface in the guest. Mostly used for firewall configuration

    # Proxy
    :squid_hostname          => "wp-proxy",                         # Hostname for the squid proxy server
    :squid_ip                => "192.168.43.10",                    # IP for the squid proxy server. Must be the first of the project.

    # Reverse proxy and load balancer
    :haproxy_hostname        => "wp-lb",                            # Hostname for the load balancer server
    :haproxy_ip              => "192.168.43.11",                    # IP for the load balancer server
    :haproxy_stats_user      => "admin",                            # Username to access the stats of HAProxy on the 1936 port (not open to eth0 nor eth1 by default)
    :haproxy_stats_password  => ENV['HAPROXY_STATS_PASSWORD'],      # Password to access the stats of HAProxy on the 1936 port (not open to eth0 nor eth1 by default)

    # Database
    :mariadb_hostname        => "wp-db",                            # Hostname for the database server
    :mariadb_ip              => "192.168.43.12",                    # IP for the database server
    :database_name           => "wordpress",                        # Defines the WordPress database name. It will only be used for the WordPress website. It uses utf8mb4 charset to support all types of characters including emojis.
    :database_username       => "wordpressuser",                    # Defines the WordPress database user. It will be only allowed to connect from web servers and have all privileges on the WordPress website database.
    :database_root_password  => ENV['DB_ROOT_PASSWORD'],            # Defines the root password for the mariadb database, which have all privileges on all the databases on the server. Root is only allowed to log in locally.
    :database_user_password  => ENV['DB_USER_PASSWORD'],            # Defines the WordPress application user password. It has all privileges only to the WordPress database, isolatingnit from the other ones if any.

    # File servers
    :glusterfs_hostname_base => "wp-file",                          # Sets the base of hostname for the file servers with GlusterFS, sequence number will be added
    :glusterfs_ip_start      => 13,                                 # Sets start of range of GlusterFS servers (for example, range 13 to 14 will give 2 servers with the default : 192.168.43.13 and 192.168.43.14)
    :glusterfs_ip_end        => 14,                                 # Sets end of range of GlusterFS servers. It will be used to configure the storage cluster. It must also be at least equal to the start of the range (1 VM)
    :glusterfs_root          => "/data",                            # Defines the root of the GlusterFS volumes on the file servers. Folder will be created at config time for 2 bricks by server.
    
    # Web servers
    :nginx_hostname_base     => "wp-web-n",                         # Sets the base of hostname for the nginx web servers, sequence number will be added
    :nginx_ip_start          => 15,                                 # Sets start of range of nginx servers. It must be the first IP of the web servers (for GlusterFS rules)
    :nginx_ip_end            => 16,                                 # Sets end of range of nginx servers. It must be at least equal to the start of the range (1 VM)
    :apache_hostname_base    => "wp-web-a",                         # Sets the base of hostname for the apache web servers, sequence number will be added
    :apache_ip_start         => 17,                                 # Sets start of range of apache servers (for example, range 17 to 17 will only provision one server with 192.168.43.17)
    :apache_ip_end           => 17,                                 # Sets end of range of apache servers. It must be at least equal to the start of the range (1 VM). Must also be the last IP of the project
    :https_enabled           => true,                               # Uses HTTPS to serve website. A valid certificate is required in cert folder. Can be disabled if no cert present.
    :domain_name             => "opensource.axelfloquet.fr",        # Name of the domain used for the website. Must match the name of the certificate to prevent warnings in browser. Must be set in /etc/hosts or %WINDIR%\System32\drivers\etc\hosts to redirect to correct IP (the HAProxy machine)
    :cert_root               => "/vagrant/cert",                    # Should not be modified. Path of the cert within the guest OS. It is used to configure the vhosts to use HTTPS. For simplicity, it is kept in a shared folder with the host and the other machines.
    :web_root                => "/var/www/html",                    # This is the folder used to mount the website files volume with GlusterFS

    # Centralized log server
    :rsyslog_hostname        => "wp-log",                           # Hostname for the centralized log server (rsyslog and filebeat)
    :rsyslog_ip              => "192.168.43.18",                    # IP for the centralized log server (rsyslog and filebeat)
    :elk_hostname            => "wp-elk",                           # Hostname for the centralized log server (ELK stack)
    :elk_ip                  => "192.168.43.19",                    # IP for the centralized log server (ELK stack)
    :kibana_domain_name      => "kibana.opensource.axelfloquet.fr", # Domain name for kibana, set in HAProxy

    # Centreon server
    :centreon_hostname       => "wp-centreon",                      # Hostname for the centreon monitoring server
    :centreon_ip             => "192.168.43.20",                    # IP for the centreon monitoring server
    :centreon_root           => "/",                                # Root for the centreon server

    # WordPress configuration
    :website_prefix          => "os1_",                             # Sets the prefix used for all the tables in the database
    # Leave all the parameters below empty for GUI install.
    :website_name            => "Projet Open Source",               # Sets the website name.
    :website_username        => "admin",                            # Sets the website username. It will be the admin user
    :website_password        => ENV['WP_ADMIN_PASSWORD'],           # Sets the admin password. Make sure to use a strong password
    :website_email           => "contact@opensource.fr",            # Sets the email address linked to the admin account
    :noindex                 => 0                                   # Defines if the website should be indexed by the search engines. 0 = do not index website. 1 = show website in search resulsts.

  }

  # Used to detect if browser has already been opened
  browser_opened = false

  # Used to apply the correct configuration for the selected protocol
  proto = (vm_params[:https_enabled]) ? "https" : "http"
  puts "### #{proto} will be used ###"

  # Save the progressbar.sh script in path
  config.vm.provision :shell, :inline => "cp -f /vagrant/common/progressbar.sh /usr/local/bin/progressbar", :name => "Install progressbar script in path"

  # Defining here the proxy VM with squid
  config.vm.define vm_params[:squid_hostname], :primary => true do |squid|
    squid.vm.hostname = vm_params[:squid_hostname]
    squid.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:squid_ip], netmask: vm_params[:netmask]

    squid.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end

    squid.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:squid_hostname], 12],                 :name => "Set hosts",                     :env => vm_params
    squid.vm.provision :shell, :path => "common/setrsyslog.sh",     :args => [vm_params[:rsyslog_hostname], 25],               :name => "Set centralized log server",    :env => vm_params
    squid.vm.provision :shell, :path => "common/apt.sh",            :args => ["neovim iptables-persistent squid rsyslog", 37], :name => "APT operations"
    squid.vm.provision :shell, :path => "common/enableservices.sh", :args => ["squid netfilter-persistent", 50],               :name => "Enable and start services"
    squid.vm.provision :shell, :path => "common/iptables.sh",       :args => 62,                                               :name => "Common firewall rules"
    squid.vm.provision :shell, :path => "squid/iptables.sh",        :args => 75,                                               :name => "Squid specific firewall rules", :env  => vm_params
    squid.vm.provision :shell, :path => "squid/config.sh",          :args => 87,                                               :name => "Squid configuration",           :env  => vm_params
    squid.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 100],                :name => "Set system proxy"
  end

  # Defining here the load balancer server with HAProxy
  config.vm.define vm_params[:haproxy_hostname] do |haproxy|
    haproxy.vm.hostname = vm_params[:haproxy_hostname]
    haproxy.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:haproxy_ip], netmask: vm_params[:netmask]

    haproxy.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end

    haproxy.vm.provision :shell, :path => "common/sethosts.sh",         :args => [vm_params[:haproxy_hostname], 12],                      :name => "Set hosts",                       :env => vm_params
    haproxy.vm.provision :shell, :path => "common/setrsyslog.sh",       :args => [vm_params[:rsyslog_hostname], 25],                      :name => "Set centralized log server",    :env => vm_params
    haproxy.vm.provision :shell, :path => "common/setproxy.sh",         :args => [vm_params[:squid_hostname], 37],                        :name => "Set system proxy"
    haproxy.vm.provision :shell, :path => "common/apt.sh",              :args => ["neovim wget haproxy iptables-persistent rsyslog", 50], :name => "APT operations"
    haproxy.vm.provision :shell, :path => "common/enableservices.sh",   :args => ["haproxy netfilter-persistent", 62],                    :name => "Enable and start services"
    haproxy.vm.provision :shell, :path => "common/iptables.sh",         :args => 75,                                                      :name => "Common firewall rules"
    haproxy.vm.provision :shell, :path => "haproxy/iptables.sh",        :args => [proto, 87],                                             :name => "HAProxy specific firewall rules", :env  => vm_params
    haproxy.vm.provision :shell, :path => "haproxy/config_#{proto}.sh", :args => 100,                                                     :name => "HAProxy configuration",           :env  => vm_params

    haproxy.vm.post_up_message = <<-MESSAGE
      #########################################################################################################
      #                                                                                                       #
      #  Your environment will be ready soon and reachable at the load balancer IP or configured domain name  #
      #      A browser window or tab will automatically open after the first web server provisioning...       #
      #    Do not forget to add the resolution for your domain name in hosts file if it not DNS resolved      #
      #                                                                                                       #
      #########################################################################################################
    MESSAGE
  end
  
  # Defining here the database server with mariadb
  config.vm.define vm_params[:mariadb_hostname] do |mariadb|
    mariadb.vm.hostname = vm_params[:mariadb_hostname]
    mariadb.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:mariadb_ip], netmask: vm_params[:netmask]

    mariadb.vm.provider :virtualbox do |vb|
      vb.cpus = 1
      vb.memory = 1536
    end

    mariadb.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:mariadb_hostname], 12],                                                  :name => "Set hosts",                       :env => vm_params
    mariadb.vm.provision :shell, :path => "common/setrsyslog.sh",     :args => [vm_params[:rsyslog_hostname], 25],                                                  :name => "Set centralized log server",      :env => vm_params
    mariadb.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 37],                                                    :name => "Set system proxy"
    mariadb.vm.provision :shell, :path => "common/apt.sh",            :args => ["neovim unzip wget mariadb-server mariadb-client iptables-persistent rsyslog", 50], :name => "APT operations"
    mariadb.vm.provision :shell, :path => "common/enableservices.sh", :args => ["mariadb netfilter-persistent", 62],                                                :name => "Enable and start services"
    mariadb.vm.provision :shell, :path => "common/iptables.sh",       :args => 75,                                                                                  :name => "Common firewall rules"
    mariadb.vm.provision :shell, :path => "mariadb/iptables.sh",      :args => 87,                                                                                  :name => "MariaDB specific firewall rules", :env  => vm_params
    mariadb.vm.provision :shell, :path => "mariadb/config.sh",        :args => 100,                                                                                 :name => "MariaDB configuration",           :env  => vm_params
  end

  # Defining here the GlusterFS file servers for the Wordpress files (looping from start to end of range of IP addresses)
  (vm_params[:glusterfs_ip_start]..vm_params[:glusterfs_ip_end]).each do |i|
    config.vm.define "#{vm_params[:glusterfs_hostname_base]}#{i}" do |glusterfs|
      glusterfs.vm.hostname = "#{vm_params[:glusterfs_hostname_base]}#{i}"
      glusterfs.vm.network :public_network, bridge: vm_params[:bridgedif], ip: "#{vm_params[:range_ip_base]}#{i}", netmask: vm_params[:netmask]

      glusterfs.vm.provider :virtualbox do |vb|
        vb.cpus = 1
        vb.memory = 1536
      end

      configure_cluster = (i == vm_params[:glusterfs_ip_end]) ? "--configure-cluster" : ""

      glusterfs.vm.provision :shell, :path => "common/sethosts.sh",       :args => ["#{vm_params[:gluster_hostname_base]}#{i}", 12],                       :name => "Set hosts",                         :env => vm_params
      glusterfs.vm.provision :shell, :path => "common/setrsyslog.sh",     :args => [vm_params[:rsyslog_hostname], 25],                                     :name => "Set centralized log server",        :env => vm_params
      glusterfs.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 37],                                       :name => "Set system proxy"
      glusterfs.vm.provision :shell, :path => "common/apt.sh",            :args => ["neovim unzip wget iptables-persistent glusterfs-server rsyslog", 50], :name => "APT operations"
      glusterfs.vm.provision :shell, :path => "common/enableservices.sh", :args => ["glusterd netfilter-persistent", 62],                                  :name => "Enable and start services"
      glusterfs.vm.provision :shell, :path => "common/iptables.sh",       :args => 75,                                                                     :name => "Common firewall rules"
      glusterfs.vm.provision :shell, :path => "glusterfs/iptables.sh",    :args => 87,                                                                     :name => "GlusterFS specific firewall rules", :env  => vm_params
      glusterfs.vm.provision :shell, :path => "glusterfs/config.sh",      :args => [configure_cluster, 100],                                               :name => "GlusterFS configuration",           :env  => vm_params
    end
  end

  # Defining here the web servers with nginx (looping from start to end of range of IP addresses)
  (vm_params[:nginx_ip_start]..vm_params[:nginx_ip_end]).each do |i|
    config.vm.define "#{vm_params[:nginx_hostname_base]}#{i}" do |nginx|
      nginx.vm.hostname = "#{vm_params[:nginx_hostname_base]}#{i}"
      nginx.vm.network :public_network, bridge: vm_params[:bridgedif], ip: "#{vm_params[:range_ip_base]}#{i}", netmask: vm_params[:netmask]

      nginx.vm.provider :virtualbox do |vb|
        vb.cpus = 1
        vb.memory = 1536
      end

      nginx.vm.provision :shell, :path => "common/sethosts.sh",       :args => ["#{vm_params[:nginx_hostname_base]}#{i}\topensource.axelfloquet.fr", 10], :name => "Set hosts",                                    :env => vm_params
      nginx.vm.provision :shell, :path => "common/setrsyslog.sh",     :args => [vm_params[:rsyslog_hostname], 20],                                        :name => "Set centralized log server",                   :env => vm_params
      nginx.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 30],                                          :name => "Set system proxy"
      nginx.vm.provision :shell, :path => "common/apt.sh",            :args => ["nginx neovim recode unzip wget php7.2-fpm php7.2-curl php7.2-gd php7.2-intl php7.2-mbstring php7.2-soap php7.2-xml php7.2-xmlrpc php7.2-zip php7.2-mysql glusterfs-client iptables-persistent rsyslog", 40], :name => "APT operations"
      nginx.vm.provision :shell, :path => "common/enableservices.sh", :args => ["nginx php7.2-fpm netfilter-persistent", 50],                             :name => "Enable and start services"
      nginx.vm.provision :shell, :path => "common/iptables.sh",       :args => 60,                                                                        :name => "Common firewall rules"
      nginx.vm.provision :shell, :path => "nginx/iptables.sh",        :args => [i, proto, 70],                                                            :name => "Nginx specific firewall rules",                :env  => vm_params
      nginx.vm.provision :shell, :path => "common/glusterfsmount.sh", :args => ["--nginx", 80],                                                           :name => "Mount GlusterFS volume",                       :env  => vm_params
      nginx.vm.provision :shell, :path => "nginx/config_#{proto}.sh", :args => 90,                                                                        :name => "Nginx configuration",                          :env  => vm_params
      nginx.vm.provision :shell, :path => "common/getwordpress.sh",   :args => [proto, 100],                                                              :name => "Wordpress install and database configuration", :env  => vm_params
    end
  end

  # Defining here the web servers with apache (looping from start to end of range of IP addresses)
  (vm_params[:apache_ip_start]..vm_params[:apache_ip_end]).each do |i|
    config.vm.define "#{vm_params[:apache_hostname_base]}#{i}" do |apache|
      apache.vm.hostname = "#{vm_params[:apache_hostname_base]}#{i}"
      apache.vm.network :public_network, bridge: vm_params[:bridgedif], ip: "#{vm_params[:range_ip_base]}#{i}", netmask: vm_params[:netmask]

      apache.vm.provider :virtualbox do |vb|
        vb.cpus = 1
        vb.memory = 1536
      end

      apache.vm.provision :shell, :path => "common/sethosts.sh",        :args => ["#{vm_params[:apache_hostname_base]}#{i}\topensource.axelfloquet.fr", 10], :name => "Set hosts",                                    :env => vm_params
      apache.vm.provision :shell, :path => "common/setrsyslog.sh",      :args => [vm_params[:rsyslog_hostname], 20],                                         :name => "Set centralized log server",                   :env => vm_params
      apache.vm.provision :shell, :path => "common/setproxy.sh",        :args => [vm_params[:squid_hostname], 30],                                           :name => "Set system proxy"
      apache.vm.provision :shell, :path => "common/apt.sh",             :args => ["apache2 neovim recode unzip wget php7.2-fpm php7.2-curl php7.2-gd php7.2-intl php7.2-mbstring php7.2-soap php7.2-xml php7.2-xmlrpc php7.2-zip php7.2-mysql glusterfs-client iptables-persistent rsyslog", 40], :name => "APT operations"
      apache.vm.provision :shell, :path => "common/enableservices.sh",  :args => ["apache2 php7.2-fpm netfilter-persistent", 50],                            :name => "Enable and start services"
      apache.vm.provision :shell, :path => "common/iptables.sh",        :args => 60,                                                                         :name => "Common firewall rules"
      apache.vm.provision :shell, :path => "apache/iptables.sh",        :args => [i, proto, 70],                                                             :name => "Apache specific firewall rules",               :env  => vm_params
      apache.vm.provision :shell, :path => "common/glusterfsmount.sh",  :args => ["--apache", 80],                                                           :name => "Mount GlusterFS volume",                       :env  => vm_params
      apache.vm.provision :shell, :path => "apache/config_#{proto}.sh", :args => 90,                                                                         :name => "Apache configuration",                         :env  => vm_params
      apache.vm.provision :shell, :path => "common/getwordpress.sh",    :args => [proto, 100],                                                               :name => "Wordpress install and database configuration", :env  => vm_params
    end
  end

  # Defining here the centralized log server ELK
  config.vm.define vm_params[:elk_hostname] do |elk|
    elk.vm.hostname = vm_params[:elk_hostname]
    elk.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:elk_ip], netmask: vm_params[:netmask]

    elk.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end

    elk.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:elk_hostname], 11],                                                           :name => "Set hosts",                       :env => vm_params
    elk.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 22],                                                         :name => "Set system proxy"
    elk.vm.provision :shell, :path => "common/apt.sh",            :args => ["apt-transport-https openjdk-11-jre neovim unzip wget iptables-persistent rsyslog", 33], :name => "APT operations (General)"
    elk.vm.provision :shell, :path => "elk/addrepo.sh",           :args => 44,                                                                                       :name => "Add Elastic repo"
    elk.vm.provision :shell, :path => "common/apt.sh",            :args => ["elasticsearch kibana logstash", 55],                                                    :name => "APT operations (ELK)"
    elk.vm.provision :shell, :path => "common/enableservices.sh", :args => ["elasticsearch kibana logstash netfilter-persistent", 66],                               :name => "Enable and start services"
    elk.vm.provision :shell, :path => "common/iptables.sh",       :args => 77,                                                                                       :name => "Common firewall rules"
    elk.vm.provision :shell, :path => "elk/iptables.sh",          :args => 88,                                                                                       :name => "ELK specific firewall rules",     :env  => vm_params
    elk.vm.provision :shell, :path => "elk/config.sh",            :args => 100,                                                                                      :name => "ELK stack configuration",         :env  => vm_params
  end

  # Defining here the centralized log server with rsyslog
  config.vm.define vm_params[:rsyslog_hostname] do |rsyslog|
    rsyslog.vm.hostname = vm_params[:rsyslog_hostname]
    rsyslog.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:rsyslog_ip], netmask: vm_params[:netmask]

    rsyslog.vm.provider :virtualbox do |vb|
      vb.cpus = 1
      vb.memory = 1024
    end

    rsyslog.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:rsyslog_hostname], 11],                    :name => "Set hosts",                       :env => vm_params
    rsyslog.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 22],                      :name => "Set system proxy"
    rsyslog.vm.provision :shell, :path => "elk/addrepo.sh",           :args => 33,                                                    :name => "Add Elastic repo"
    rsyslog.vm.provision :shell, :path => "common/apt.sh",            :args => ["neovim unzip wget iptables-persistent rsyslog", 44], :name => "APT operations (General)"
    rsyslog.vm.provision :shell, :path => "common/apt.sh",            :args => ["filebeat", 55],                                      :name => "APT operations (Filebeat)"
    rsyslog.vm.provision :shell, :path => "common/enableservices.sh", :args => ["rsyslog filebeat netfilter-persistent", 66],         :name => "Enable and start services"
    rsyslog.vm.provision :shell, :path => "common/iptables.sh",       :args => 77,                                                    :name => "Common firewall rules"
    rsyslog.vm.provision :shell, :path => "rsyslog/iptables.sh",      :args => 88,                                                    :name => "Rsyslog specific firewall rules", :env  => vm_params
    rsyslog.vm.provision :shell, :path => "rsyslog/config.sh",        :args => 100,                                                   :name => "Rsyslog configuration",           :env  => vm_params
  end

  # Defining here the centreon monitoring server
  config.vm.define vm_params[:centreon_hostname] do |centreon|
    centreon.vm.hostname = vm_params[:centreon_hostname]
    centreon.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:centreon_ip], netmask: vm_params[:netmask]

    centreon.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 1024
    end

    centreon.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:centreon_hostname], 11], :name => "Set hosts",                  :env => vm_params
    centreon.vm.provision :shell, :path => "common/setrsyslog.sh",     :args => [vm_params[:rsyslog_hostname], 22],  :name => "Set centralized log server", :env => vm_params
    centreon.vm.provision :shell, :path => "common/setproxy.sh",       :args => [vm_params[:squid_hostname], 33],    :name => "Set system proxy"
    centreon.vm.provision :shell, :path => "centreon/addrepo.sh",      :args => 44,                                  :name => "Add NodeJS repo"
    centreon.vm.provision :shell, :path => "common/apt.sh",            :args => ["build-essential cmake libperl-dev libssh2-1-dev libgcrypt11-dev libcgsi-gsoap-dev zlib1g-dev libssl-dev libxerces-c-dev libgnutls28-dev libssl-dev libkrb5-dev libldap2-dev libsnmp-dev gawk libwrap0-dev libmcrypt-dev smbclient fping gettext dnsutils libmysqlclient-dev libxml-libxml-perl libjson-perl libwww-perl libxml-xpath-perl libnet-telnet-perl libnet-ntp-perl libnet-dns-perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl libdatetime-perl liburi-encode-perl libdate-manip-perl git-core snmp snmpd snmptrapd libnet-snmp-perl libsnmp-perl librrd-dev libqt4-dev libqt4-sql-mysql libgnutls28-dev lsb-release liblua5.2-dev snmp-mibs-downloader apt-transport-https lsb-release ca-certificates php7.2 php7.2-opcache apache2 libapache2-mod-php7.2 php7.2-mysql php7.2-curl php7.2-json php7.2-gd php7.2-intl php7.2-mbstring php7.2-xml php7.2-zip php7.2-fpm php7.2-readline php7.2-sqlite3 php-pear sudo tofrodos bsd-mailx lsb-release mariadb-server rrdtool librrds-perl libconfig-inifiles-perl libcrypt-des-perl libdigest-hmac-perl libdigest-sha-perl libgd-perl php7.2-ldap php7.2-snmp php-db php-date nodejs", 55], :name => "APT operations"
    #centreon.vm.provision :shell, :path => "common/iptables.sh",       :args => 66,
    #centreon.vm.provision :shell, :path => "centreon/iptables.sh",     :args => 77,
    centreon.vm.provision :shell, :path => "centreon/config.sh",       :args => 88,                                  :name => "Centreon configuration",     :env => vm_params
    centreon.vm.provision :shell, :path => "common/enableservices.sh", :args => ["centengine cbd", 100],             :name => "Enable and start services"
  end

  # Open browser after setting up / booting up one or several web servers
  config.trigger.after [:up, :provision, :reload, :resume], only_on: [/#{vm_params[:nginx_hostname_base]}\d{1,3}/, /#{vm_params[:apache_hostname_base]}\d{1,3}/] do |trigger|
    trigger.ruby do |env,machine|
      if browser_opened then
        puts "Browser has already been launched, skipping trigger"
      else
        browser_opened = true
        puts "Launch website in default host browser"
        if /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM then           # If OS is Windows
          system("#{ENV['WINDIR']}\\explorer.exe", "https://#{vm_params[:domain_name]}")
        else
          system("open", "https://#{vm_params[:domain_name]}")
        end
      end
    end
  end
end
