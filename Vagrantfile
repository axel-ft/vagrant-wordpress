# -*- mode: ruby -*-
# vi: set ft=ruby :

###########################################################################################################################################
#                            Deploying 2 VM with Vagrant : 1  web server (wordpress), and one database server                             #
# This script uses a folder called cert placed aside this file, which contains all the files generated by Let's Encrypt for HTTPS serving #
#                                                      Author: Axel Floquet-Trillot                                                       #
###########################################################################################################################################

Vagrant.configure("2") do |config|
  # Checking, and maybe installing vagrant-env plugin if it is not present to retrieve passwords from .env file
  puts "Installing missing plugin vagrant-env..."
  config.vagrant.plugins = "vagrant-env"

  # Check updates and use use Ubuntu 18.04 image from Hashicorp
  config.vm.box = "hashicorp/bionic64"
  config.vm.box_check_update = true

  # Use the .env file to load passwords
  config.env.enable
  config.vagrant.sensitive = [ENV['DB_ROOT_PASSWORD'], ENV['DB_USER_PASSWORD'], ENV['WP_ADMIN_PASSWORD']]

  # Define all variables here in a flat hash (nested hash cannot be used easily in provision)
  # All params are transmitted to scripts with environment variables
  vm_params = {
    # Network configuration
    :netmask                 => "255.255.255.0",                    # Cannot be wider that a 255.255.255.0 network (scripts won't work)
    :bridgeif                => "Intel(R) Wireless-AC 9560 160MHz", # Name of the interface to bridge. Command "VBoxManage list bridgedifs" is used to obtain the correct name
    :bridgeif_guest_name     => "eth1",                             # Name of the bridged interface in the guest. Mostly used for firewall configuration

    # Database
    :mariadb_hostname        => "wp-db",                            # Hostname for the database server
    :mariadb_ip              => "192.168.43.10",                    # IP for the database server
    :database_name           => "wordpress",                        # Defines the WordPress database name. It will only be used for the WordPress website. It uses utf8mb4 charset to support all types of characters including emojis.
    :database_username       => "wordpressuser",                    # Defines the WordPress database user. It will be only allowed to connect from web servers and have all privileges on the WordPress website database.
    :database_root_password  => ENV['DB_ROOT_PASSWORD'],            # Defines the root password for the mariadb database, which have all privileges on all the databases on the server. Root is only allowed to log in locally.
    :database_user_password  => ENV['DB_USER_PASSWORD'],            # Defines the WordPress application user password. It has all privileges only to the WordPress database, isolatingnit from the other ones if any.

    # Web servers
    :nginx_hostname          => "wp-web",                           # Sets the hostname for the nginx web server
    :nginx_ip                => "192.168.43.11",                    # IP of the web server
    :https_enabled           => true,                               # Uses HTTPS to serve website. A valid certificate is required in cert folder. Can be disabled if no cert present.
    :domain_name             => "opensource.axelfloquet.fr",        # Name of the domain used for the website. Must match the name of the certificate to prevent warnings in browser. Must be set in /etc/hosts or %WINDIR%\System32\drivers\etc\hosts to redirect to correct IP (the HAProxy machine)
    :cert_root               => "/vagrant/cert",                    # Should not be modified. Path of the cert within the guest OS. It is used to configure the vhosts to use HTTPS. For simplicity, it is kept in a shared folder with the host and the other machines.
    :web_root                => "/var/www/html",                    # This is the folder used for the website files

    # WordPress configuration
    :website_prefix          => "os1_",                             # Sets the prefix used for all the tables in the database
    # Leave all the parameters below empty for GUI install.
    :website_name            => "Open Source Exo 1",                # Sets the website name.
    :website_username        => "admin",                            # Sets the website username. It will be the admin user
    :website_password        => ENV['WP_ADMIN_PASSWORD'],           # Sets the admin password. Make sure to use a strong password
    :website_email           => "contact@opensource.fr",            # Sets the email address linked to the admin account
    :noindex                 => 0                                   # Defines if the website should be indexed by the search engines. 0 = do not index website. 1 = show website in search resulsts.
  }

  # Used to apply the correct configuration for the selected protocol
  proto = (vm_params[:https_enabled]) ? "https" : "http"
  puts "### #{proto} will be used ###"

  # Save the progressbar.sh script in path
  config.vm.provision :shell, :inline => "cp -f /vagrant/common/progressbar.sh /usr/local/bin/progressbar", :name => "Install progressbar script in path"

  # Defining here the database server with mariadb
  config.vm.define vm_params[:mariadb_hostname] do |mariadb|
    mariadb.vm.hostname = vm_params[:mariadb_hostname]
    mariadb.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:mariadb_ip], netmask: vm_params[:netmask]

    mariadb.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end

    mariadb.vm.provision :shell, :path => "common/sethosts.sh",       :args => [vm_params[:mariadb_hostname], 16],                                            :name => "Set hosts",                       :env => vm_params
    mariadb.vm.provision :shell, :path => "common/apt.sh",            :args => ["neovim unzip wget mariadb-server mariadb-client iptables-persistent", 33],   :name => "APT operations"
    mariadb.vm.provision :shell, :path => "common/enableservices.sh", :args => ["mariadb netfilter-persistent", 49],                                          :name => "Enable and start services"
    mariadb.vm.provision :shell, :path => "common/iptables.sh",       :args => 65,                                                                            :name => "Common firewall rules"
    mariadb.vm.provision :shell, :path => "mariadb/iptables.sh",      :args => 81,                                                                            :name => "MariaDB specific firewall rules", :env  => vm_params
    mariadb.vm.provision :shell, :path => "mariadb/config.sh",        :args => 100,                                                                           :name => "MariaDB configuration",           :env  => vm_params
  end

  # Defining here the web server with nginx
  config.vm.define vm_params[:nginx_hostname] do |nginx|
    nginx.vm.hostname = vm_params[:nginx_hostname_base]
    nginx.vm.network :public_network, bridge: vm_params[:bridgedif], ip: vm_params[:nginx_ip], netmask: vm_params[:netmask]

    nginx.vm.provider :virtualbox do |vb|
      vb.cpus = 2
      vb.memory = 2048
    end

    nginx.vm.provision :shell, :path => "common/sethosts.sh",       :args => ["#{vm_params[:nginx_hostname]}\topensource.axelfloquet.fr", 14],            :name => "Set hosts",                                    :env => vm_params
    nginx.vm.provision :shell, :path => "common/apt.sh",            :args => ["nginx neovim recode unzip wget php7.2-fpm php7.2-curl php7.2-gd php7.2-intl php7.2-mbstring php7.2-soap php7.2-xml php7.2-xmlrpc php7.2-zip php7.2-mysql iptables-persistent", 28], :name => "APT operations"
    nginx.vm.provision :shell, :path => "common/enableservices.sh", :args => ["nginx php7.2-fpm netfilter-persistent", 42],                               :name => "Enable and start services"
    nginx.vm.provision :shell, :path => "common/iptables.sh",       :args => 56,                                                                          :name => "Common firewall rules"
    nginx.vm.provision :shell, :path => "nginx/iptables.sh",        :args => [proto, 70],                                                                 :name => "Nginx specific firewall rules",                :env  => vm_params
    nginx.vm.provision :shell, :path => "nginx/config_#{proto}.sh", :args => 84,                                                                          :name => "Nginx configuration",                          :env  => vm_params
    nginx.vm.provision :shell, :path => "common/getwordpress.sh",   :args => [proto, 100],                                                                :name => "Wordpress install and database configuration", :env  => vm_params
  end

  # Open browser after setting up / booting up one or several web servers
  config.trigger.after [:up, :provision, :reload, :resume], only_on: vm_params[:nginx_hostname] do |trigger|
    trigger.ruby do |env,machine|
      puts "Launch website in default host browser"
      if /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM then           # If OS is Windows
        system("#{ENV['WINDIR']}\\explorer.exe", "#{proto}://#{vm_params[:domain_name]}")
      else
        system("open", "#{proto}://#{vm_params[:domain_name]}")
      end
    end
  end
end
