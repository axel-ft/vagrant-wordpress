# Wordpress environment deployment with Vagrant

![Network Topology](network.png)

This project can be used to deploy a complete Wordpress install in less than half an hour. Vagrant is used to deploy and provision all the virtual machines. The Vagrantfile included, and customizable, is used to deploy the following machines (defaults values are shown):

|  Qty  | Scalable |           Type            | Package | Hostname |      IP       |  CPU  |  RAM  |
| :---: | :------: | :-----------------------: | :-----: | :------: | :-----------: | :---: | :---: |
|   1   |    ❌     |           Proxy           |  squid  | wp-proxy | 192.168.43.10 |   2   |  2GB  |
|   1   |    ❌     | Database (WordPress data) | mariadb |  wp-db   | 192.168.43.12 |   1   | 1.5GB |
|   1   |    ✔     |     Nginx web servers     |  nginx  |  wp-web  | 192.168.43.11 |   1   | 1.5GB |

> - All the machines access have been secured with iptables and iptables-persistent to make rules permanent even after rebooting the machine.

## Usage

> [VirtualBox](https://www.virtualbox.org/wiki/Downloads) is required to deploy this installation, as well as [Vagrant](https://www.vagrantup.com/downloads.html). The `vagrant-dotenv` plugin is used to load the passwords without displaying them in the `Vagrantfile` or in the git repo. The plugin [vagrant-env](https://github.com/gosuri/vagrant-env) is installed with `vagrant plugin install vagrant-env` or automatically during the first deployment.

Before executing any command, a `.env` file must be placed along with the `Vagrantfile` and filled with the four passwords used in the project in the following way :

```bash
# A template for this .env file is placed at the root of this project. You can copy it under the .env name and modify it to your needs.
DB_ROOT_PASSWORD="Root password for the database"
DB_USER_PASSWORD="Wordpress user password for the database"
WP_ADMIN_PASSWORD="Wordpress admin user password"
```

Once the environment variables are ready, the project can be deployed easily with one command : `vagrant up` from the project folder.

However, with the default values, some configurations of machines may fail due to network changes or computer resources. With my cellular network share, the network `192.168.43.0/24` is used and I took the 10 to 12 IP range. Moreover, deploying these 3 machines can only run in a computer with at least 16 GB of RAM. An i5 CPU is also recommended. All of these settings are customizable, as described in the following section

## Common parameters and configuration

Some scripts in this projects are applied to all the machines, configuring some basics things in each system. Most of these scripts use an hash of variables declared in the beginning of the **`Vagrantfile`**. This hash, named `vm_params`, contains all the informations of the project environment. It allows to :

- Define each hostname and IP address of the machines with *`xxxx_hostname`* and *`xxxx_ip`*. The IP address corresponds to the bridged interface and is unique for the proxy, database, and web server.
- Define the `netmask` for all machines and defaulting to `255.255.255.0` which is high enough for this project.
- Define which interface is bridged with `bridgedif`. This is the name of the interface as displayed as in the result of the `VBoxManage list bridgedifs` command, chosing the right interface with Internet access.
- Define the name of the guest bridged interface with `bridgeif_guest_name`. In all the guests, the bridged interface is the second NIC and is named `eth1` by default.
- Define the `domain_name` which is given to the vhost configuration and also should match the certificate name to prevent warnings in the browser when visiting the website.
- Define the root of the certificates files. By default, the certificate files are placed in a `cert` directory right next to the `Vagrantfile` and the `cert_root` variable points towards them. Note that for simplicity, they are kept on a shared folder between the guests and the host machine. They are not pushed to any folder in the virtual machines.
- Define the `web_root` to store the website files. It is the root folder for the vhost (in web server), defaulting to `/var/www/html`. ⚠ Contents of the folder will be removed during deployment. Be cautious not to place the folder anywhere critical for the system.
- Define the different database or WordPress variables. Go to the Database and WordPress sections to see more details on that part.

All those variables are transmitted as environment variables to the provisioning scripts when necessary (a warning header is included in each script where they are used). This allow to modify in one place all the parameters without having to replace each occurence in the files of the project.

### Parameters summary

All these parameters are found at the begining of the `Vagrantfile` or in the `.env` file.

|          Name          |  Type   |          Default value           |                Usage                 |                            Constraints                             |
| :--------------------: | :-----: | :------------------------------: | :----------------------------------: | :----------------------------------------------------------------: |
|        netmask         | String  |          255.255.255.0           |    Netmask used for all machines     |                    /24 or less network required                    |
|        bridgeif        | String  | Intel(R) Wireless-AC 9560 160MHz |      Name of the host interface      |                  see `VBoxManage list bridgedifs`                  |
|  bridgeif_guest_name   | String  |               eth1               |     Name of the guest interface      |                           See `ip -c a`                            |
|     squid_hostname     | String  |             wp-proxy             |          Hostname of proxy           |                               Unique                               |
|        squid_ip        | String  |          192.168.43.10           |             IP of proxy              |                               Unique                               |
|    mariadb_hostname    | String  |              wp-db               |       Hostname of the database       |                               Unique                               |
|       mariadb_ip       | String  |          192.168.43.12           |          IP of the database          |                               Unique                               |
|     database_name      | String  |            wordpress             |         Name of the database         |           Unique, not equal to mysql, information_schema           |
|   database_username    | String  |          wordpressuser           |    Username of the WordPress user    |                   Unique, no special characters                    |
| database_root_password | String  |                                  | Password for the root database user  |                       Defined in `.env` file                       |
| database_user_password | String  |                                  |   Password for the wordpress user    |                       Defined in `.env` file                       |
|     nginx_hostname     | String  |              wp-web              |      Hostname for Nginx server       |                               Unique                               |
|        nginx_ip        | Number  |          192.168.43.11           |          IP of Nginx server          |                               Unique                               |
|     https_enabled      | Boolean |               true               |       Defines if HTTPS is used       |              If true, a valid certificate is required              |
|      domain_name       | String  |    opensource.axelfloquet.fr     |             Domain name              |       Valid and resolved (in hosts or DNS) domain name or IP       |
|       cert_root        | String  |          /vagrant/cert           |        Certificate files root        | Valid certificate for the above domain (Let's Encrypt for example) |
|        web_root        | String  |          /var/www/html           |          Website files root          |           Valid existing path - Emptied on provisioning            |
|     website_prefix     | String  |               os1_               |        Prefix for table names        |                  Short and no special characters                   |
|      website_name      | String  |           Open Source            |         Title of the website         |      Can be omitted for GUI install - No special constraints       |
|    website_username    | String  |              admin               | Username of the admin WordPress user |      Can be omitted for GUI install - No special constraints       |
|    website_password    | String  |                                  |     Password of this admin user      |  Can be omitted for GUI install - Strong passwords only in `.env`  |
|     website_email      | String  |      contact@opensource.fr       |     Email for this admin account     |        Can be omitted for GUI install - valid mail address         |
|        noindex         | Number  |                0                 |        Search engine indexing        |                            Only 0 or 1                             |

> Omitted allowed parameters are just left empty

### Hosts

This project does not include a DNS server. So, in order to be able to use hostnames, the `/etc/hosts` file of each machine is configured to resolve all the other machines of the project. The result of the corresponding script used like this `./common/sethosts.sh current_hostname` gives as example the following result file :

```bash
127.0.0.1       localhost       wp-web      opensource.axelfloquet.fr
127.0.1.1       wp-web          wp-web

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
192.168.43.10   wp-proxy
192.168.43.11   wp-web
192.168.43.12   wp-db
```

### APT

All systems needs package installation with each one its specific requirements. For this purpose, a simple script used as `.common/apt.sh 'list of packages here'` does the operation of updating the repos, installing the given packages, as well as upgrading the system (this last command is commented for speed purposes in test deployments).

### Enable services

Services also needs to be enabled on each system. To be able to enable and start them, this three line script is used as follow :

```bash
./common/enableservices.sh 'service_1 service_2'
```

### Iptables

All servers have iptables configured to allow only the necessary services. Some rules are common to all machines. Hence, they are place in this script used to provision all the machines :

```bash
./common/iptables.sh
```

This file includes protection against ICMP bursts, several port scans, and defines the default policies for input, forward and output (but it can be overriden on each host). SSH, DNS and NTP are also added to be accepted. As it is a common script, no specific rule is found here but each machine have an `iptables.sh` script for custom rules in the corresponding folder. Some of these scripts may require an argument, you can open them and see each header with a usage instruction to know.

## Proxy server

The proxy server, Squid, is necessary for all the machines to be able to reach Internet. It is not scalable and is automatically configured on all hosts of this project via the `common/setproxy.sh` script used this way :

```bash
./common/setproxy.sh wp-proxy
```

Access to the Internet without proxy is prevented by the firewall.

## Database

MariaDB has been used for the database on one host only. It is not replicated and not in high availability in this project. Only one database for the WordPress website is configured with all privileges users for each web server. Iptables is also configured to let access to the database only to the web servers. A few variables are available to configure the database :

- database_name : the name of the database. Defaults to `wordpress`
- database_user : the name of the WordPress user. Defaults to `wordpressuser`.
- database_root_password : the password for the root user.
- database_user_password : the password for the WordPress user.

## Nginx web server

One vhost is configured to give HTTPS access by default to the wordpress install. Iptables rules are also configured to allow access to the website only. This is also the only machine to be able to access to the database. The configuration used is mostly the default vhost configuration given by WordPress in their documentation. If you want to disable HTTPS, you can set the `https_enabled` to `false`.

## WorpPress

The latest version of WordPress is automatically downloaded and installed after the creation of the worpdress GlusterFS volume. It is also configured automatically to use the previously created database, generating the well known `wp-config.php` in the process. If the website itself is defined in the variables, it is also configured ans saved to the database. In case of anything going wrong, nothing is done and the normal graphical installation can be accessed upon first connection. Here are the variables that can be set to install the website :

- `website_name` : sets the title of the WordPress install. Defaults to `Open Source Exo 2`.
- `website_username` : sets the username of the administrative user. Defaults to `admin`.
- `website_password` : sets the password of the administrative user.
- `website_email` : sets the email associated to the administrative user. Defaults to `contact@opensource.fr`
- `noindex` : this variable is used to tell the search engines what to do with the website. Two values are possible :
  - 0 : Website will not be indexed and will not show up in search results.
  - 1 : Website will be indexed and show up in the search results.
