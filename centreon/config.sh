#!/usr/bin/env bash

################################################################################################################
# config.sh - Compilation, installation and configuration script for centreon                                  #
# Usage : ./config.sh [current_progress]                                                                       #
# Author: Charly Estay, Matthieu Poulier                                                                       #
################################################################################################################

check() {
	if [[ $1 -ne 0 ]]; then
		echo "$2: $3 failed !"
		exit 1
	fi
}

# Define variables
DOWNLOAD_DIR="/usr/local/src"

CENTREON_CLIB="http://files.download.centreon.com/public/centreon-clib/centreon-clib-18.10.0.tar.gz"
CENTREON_CLIB_TGZ="centreon-clib-18.10.0.tar.gz"
CENTREON_CLIB_DIR="centreon-clib-18.10.0/build"

CENTREON_CONNECTORS="http://files.download.centreon.com/public/centreon-connectors/centreon-connectors-18.10.0.tar.gz"
CENTREON_CONNECTORS_TGZ="centreon-connectors-18.10.0.tar.gz"
CENTREON_PERL_CONNECTOR_DIR="centreon-connector-18.10.0/perl/build"
CENTREON_SSH_CONNECTOR_DIR="centreon-connector-18.10.0/ssh/build"

CENTREON_ENGINE="http://files.download.centreon.com/public/centreon-engine/centreon-engine-18.10.0.tar.gz"
CENTREON_ENGINE_TGZ="centreon-engine-18.10.0.tar.gz"
CENTREON_ENGINE_DIR="centreon-engine-18.10.0/build"

NAGIOS_PLUGINS="http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz"
NAGIOS_PLUGINS_TGZ="nagios-plugins-2.2.1.tar.gz"
NAGIOS_PLUGINS_DIR="nagios-plugins-2.2.1"

MONITORING_PLUGINS="https://www.monitoring-plugins.org/download/monitoring-plugins-2.2.tar.gz"
MONITORING_PLUGINS_TGZ="monitoring-plugins-2.2.tar.gz"
MONITORING_PLUGINS_DIR="monitoring-plugins-2.2"

CENTREON_PLUGINS="http://files.download.centreon.com/public/centreon-plugins/centreon-plugins-20191016.tar.gz"
CENTREON_PLUGINS_TGZ="centreon-plugins-20191016.tar.gz"
CENTREON_PLUGINS_DIR="centreon-plugins-20191016"

CENTREON_BROKER="http://files.download.centreon.com/public/centreon-broker/centreon-broker-18.10.1.tar.gz"
CENTREON_BROKER_TGZ="centreon-broker-18.10.1.tar.gz"
CENTREON_BROKER_DIR="centreon-broker-18.10.1/build"

CENTREON_UI="http://files.download.centreon.com/public/centreon/centreon-web-18.10.7.tar.gz"
CENTREON_UI_TGZ="centreon-web-18.10.7.tar.gz"
CENTREON_UI_DIR="centreon-web-18.10.7"

CENTREON_ENGINE_PLUGIN="http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz"
CENTREON_ENGINE_PLUGIN_TGZ="nagios-plugins-2.2.1.tar.gz"

# Create users and groups
sudo groupadd -g 6001 centreon-engine
sudo useradd -u 6001 -g centreon-engine -m -r -d /var/lib/centreon-engine -c "Centreon-engine Admin" -s /bin/bash centreon-engine

sudo groupadd -g 6002 centreon-broker
sudo useradd -u 6002 -g centreon-broker -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" -s /bin/bash centreon-broker
sudo usermod -aG centreon-broker centreon-engine

sudo groupadd -g 6000 centreon
sudo useradd -u 6000 -g centreon -m -r -d /var/lib/centreon -c "Centreon Admin" -s /bin/bash centreon
sudo usermod -aG centreon centreon-broker

# Download and extract packages
cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/bin --filename=composer

cd ${DOWNLOAD_DIR}
NAME="Centreon Clib"
wget --progress=bar:force "${CENTREON_CLIB}" && tar -xzf "${CENTREON_CLIB_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon Connectors"
wget --progress=bar:force "${CENTREON_CONNECTORS}" && tar -xzf "${CENTREON_CONNECTORS_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon Engine"
wget --progress=bar:force "${CENTREON_ENGINE}" && tar -xzf "${CENTREON_ENGINE_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon Engine Plugins"
wget --progress=bar:force "${CENTREON_ENGINE_PLUGIN}" && tar -xzf "${CENTREON_ENGINE_PLUGIN_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon Broker"
wget --progress=bar:force "${NAGIOS_PLUGINS}" && tar -xzf "${NAGIOS_PLUGINS_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon Monitoring Plugins"
wget --progress=bar:force --no-check-certificate "${MONITORING_PLUGINS}" && tar -xzf "${MONITORING_PLUGINS_TGZ}"
check $? "${NAME}" "download"
wget --progress=bar:force "${CENTREON_PLUGINS}" && tar -xzf "${CENTREON_PLUGINS_TGZ}" 
check $? "${NAME}" "download"

NAME="Centreon Broker"
wget --progress=bar:force "${CENTREON_BROKER}" && tar -xzf "${CENTREON_BROKER_TGZ}"
check $? "${NAME}" "download"

NAME="Centreon UI"
wget --progress=bar:force "${CENTREON_UI}" && tar -xzf "${CENTREON_UI_TGZ}"
check $? "${NAME}" "download"

# Compile all parts and install
NAME="Centreon Clib"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${CENTREON_CLIB_DIR}" > /dev/null 
        cmake \
            -DWITH_TESTING=0 \
            -DWITH_PREFIX=/usr  \
            -DWITH_SHARED_LIB=1 \
            -DWITH_STATIC_LIB=0 \
            -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig .
        make
        sudo make install
        check $? "${NAME}" "build"
    popd > /dev/null
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon Perl Connector"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${CENTREON_PERL_CONNECTOR_DIR}" > /dev/null
        cmake \
            -DWITH_PREFIX=/usr \
            -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector \
            -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
            -DWITH_TESTING=0 .

        make                                                                                                                
        sudo make install
        check $? "${NAME}" "build"
    popd > /dev/null
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon SSH Connector"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${CENTREON_SSH_CONNECTOR_DIR}" > /dev/null
        cmake \
            -DWITH_PREFIX=/usr \
            -DWITH_PREFIX_BINARY=/usr/lib/centreon-connector  \
            -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include \
            -DWITH_TESTING=0 .

        make
        sudo make install
        check $? "${NAME}" "build"
    popd > /dev/null
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon Engine"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${CENTREON_ENGINE_DIR}" > /dev/null
        cmake  \
            -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include  \
            -DWITH_CENTREON_CLIB_LIBRARY_DIR=/usr/lib  \
            -DWITH_PREFIX=/usr  \
            -DWITH_PREFIX_BIN=/usr/sbin  \
            -DWITH_PREFIX_CONF=/etc/centreon-engine  \
            -DWITH_USER=centreon-engine  \
            -DWITH_GROUP=centreon-engine  \
            -DWITH_LOGROTATE_SCRIPT=1 \
            -DWITH_VAR_DIR=/var/log/centreon-engine  \
            -DWITH_RW_DIR=/var/lib/centreon-engine/rw  \
            -DWITH_STARTUP_SCRIPT=systemd  \
            -DWITH_STARTUP_DIR=/lib/systemd/system  \
            -DWITH_PKGCONFIG_SCRIPT=1 \
            -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig  \
            -DWITH_TESTING=0  .

        make
        sudo make install 
    popd > /dev/null

    sudo systemctl enable centengine.service
    sudo systemctl daemon-reload
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon Engine Plugins"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd nagios-plugins-2.2.1 > /dev/null
        cmake  \
            -DWITH_CENTREON_CLIB_INCLUDE_DIR=/usr/include  \
            -DWITH_CENTREON_CLIB_LIBRARY_DIR=/usr/lib  \
            -DWITH_PREFIX=/usr  \
            -DWITH_PREFIX_BIN=/usr/sbin  \
            -DWITH_PREFIX_CONF=/etc/centreon-engine  \
            -DWITH_USER=centreon-engine  \
            -DWITH_GROUP=centreon-engine  \
            -DWITH_LOGROTATE_SCRIPT=1 \
            -DWITH_VAR_DIR=/var/log/centreon-engine  \
            -DWITH_RW_DIR=/var/lib/centreon-engine/rw  \
            -DWITH_STARTUP_SCRIPT=systemd  \
            -DWITH_STARTUP_DIR=/lib/systemd/system  \
            -DWITH_PKGCONFIG_SCRIPT=1 \
            -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig  \
            -DWITH_TESTING=0  .

        make
        sudo make install
    popd > /dev/null
    sudo systemctl enable centengine.service
    sudo systemctl daemon-reload
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon Monitoring Plugins"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${NAGIOS_PLUGINS_DIR}" > /dev/null
        ./configure --with-nagios-user=centreon-engine --with-nagios-group=centreon-engine --prefix=/usr/lib/nagios/plugins --libexecdir=/usr/lib/nagios/plugins --enable-perl-modules --with-openssl=/usr/bin/openssl
        make 
        sudo make install
    popd > /dev/null

    pushd "${MONITORING_PLUGINS_DIR}" > /dev/null
        ./configure --with-nagios-user=centreon-engine --with-nagios-group=centreon-engine --prefix=/usr/lib/nagios/plugins --libexecdir=/usr/lib/nagios/plugins --enable-perl-modules --with-openssl=/usr/bin/openssl
        make 
        sudo make install
    popd > /dev/null

    pushd "${CENTREON_PLUGINS_DIR}" > /dev/null
        chmod +x *
        sudo mkdir -p /usr/lib/centreon/plugins
        cp -R * /usr/lib/centreon/plugins/
    popd > /dev/null
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon Broker"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    pushd "${CENTREON_BROKER_DIR}" > /dev/null
        sed -i '32i\set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++98 -fpermissive")' CMakeLists.txt
        cmake \
            -DWITH_DAEMONS='central-broker;central-rrd' \
            -DWITH_GROUP=centreon-broker \
            -DWITH_PREFIX=/usr  \
            -DWITH_PREFIX_BIN=/usr/sbin  \
            -DWITH_PREFIX_CONF=/etc/centreon-broker  \
            -DWITH_PREFIX_LIB=/usr/lib/centreon-broker \
            -DWITH_PREFIX_VAR=/var/lib/centreon-broker \
            -DWITH_PREFIX_MODULES=/usr/share/centreon/lib/centreon-broker \
            -DWITH_STARTUP_SCRIPT=systemd  \
            -DWITH_STARTUP_DIR=/lib/systemd/system  \
            -DWITH_TESTING=0 \
            -DWITH_USER=centreon-broker .

        make
        sudo make install
    popd > /dev/null

    sudo systemctl enable cbd.service
    sudo systemctl daemon-reload
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

# Configuration
NAME="SNMP Protocol"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
cat << SNMPD > /etc/snmp/snmpd.conf
agentAddress  udp:127.0.0.1:161
view   systemonly  included   .1.3.6.1.2.1.1
view   systemonly  included   .1.3.6.1.2.1.25.1
 rocommunity public localhost
 rocommunity6 public  default   -V systemonly
 rouser   authOnlyUser
sysLocation    Sitting on the Dock of the Bay
sysContact     Me <me@example.org>
sysServices    72
proc  mountd
proc  ntalkd    4
proc  sendmail 10 1
disk       /     10000
disk       /var  5%
includeAllDisks  10%
load   12 10 5
 trapsink        localhost       public
iquerySecName   internalUser
rouser          internalUser
 extend    test1   /bin/echo  Hello, world!
 extend-sh test2   echo Hello, world! ; echo Hi there ; exit 35
 master          agentx
SNMPD

    sed -i "s/SNMPDOPTS='-Lsd -Lf \/dev\/null -u Debian-snmp -g Debian-snmp -I -smux,mteTrigger,mteTriggerConf -p \/run\/snmpd.pid'/SNMPDOPTS='-LS4d -Lf \/dev\/null -u snmp -g snmp -I -smux,mteTrigger,mteTriggerConf -p \/var\/run\/snmpd.pid'/" /etc/default/snmpd

    sed -i -e 's/TRAPDRUN=no/TRAPDRUN=yes/' -e "s/TRAPDOPTS='-Lsd -p \/run\/snmptrapd.pid'/TRAPDOPTS='-On -Lsdf \/var\/log\/snmptrapd.log -p \/run\/snmptrapd.pid'/" /etc/default/snmptrapd
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="MIBS"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    sed -i -e 's/export MIBS=/export MIBDIRS=\/usr\/share\/snmp\/mibs\nexport MIBS=ALL/' /etc/default/snmpd
    sed -i -e 's/mibs :/#mibs :\n#mibs ALL/' /etc/snmp/snmp.conf

    sudo systemctl restart snmpd
    sudo systemctl restart snmptrapd
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

NAME="Centreon UI"
echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                   ${NAME}                    ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"
    # Configure database
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('${database_root_password}') WHERE User='root';"      # Define root password
    mysql -e "DELETE FROM mysql.user WHERE User='';"                                                        # Remove anonymous users
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"  # Remove remote access for root
    mysql -e "DROP DATABASE IF EXISTS test;"                                                                # Drop test database
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"                                        # Drop test database information
    mysql -e "FLUSH PRIVILEGES;"
    mysql -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '${database_root_password}'; FLUSH PRIVILEGES;"
    sed -i -e 's/LimitNOFILE=16364/LimitNOFILE=32000/' /etc/systemd/system/multi-user.target.wants/mariadb.service
    mkdir -p /etc/systemd/system/mariadb.service.d
    cat << SYSTEMD > /etc/systemd/system/mariadb.service.d/override.conf
[Service]

LimitNOFILE=32000
SYSTEMD
    sed -i -e 's/skip-external-locking/skip-external-locking\nopen_files_limit=32000/' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl daemon-reload
    systemctl restart mariadb

    # Configure PHP and Apache
    sed -i -e 's/;date.timezone =/date.timezone = Europe\/Paris/' /etc/php/7.2/apache2/php.ini
    sed -i -e 's/;date.timezone =/date.timezone = Europe\/Paris/' /etc/php/7.2/fpm/php.ini

    sudo a2enmod proxy_fcgi setenvif proxy rewrite
    sudo a2enconf php7.2-fpm
    sudo a2dismod php7.2
    sudo systemctl restart apache2 php7.2-fpm

    # Install Centreon website
    pushd "${CENTREON_UI_DIR}"
        cat > /usr/local/src/centreon_engine.tmpl << EOF
# Centreon template
PROCESS_CENTREON_WWW=1
PROCESS_CENTSTORAGE=1
PROCESS_CENTCORE=1
PROCESS_CENTREON_PLUGINS=1
PROCESS_CENTREON_SNMP_TRAPS=1
LOG_DIR="$BASE_DIR/log"
LOG_FILE="$LOG_DIR/install_centreon.log"
TMPDIR="/tmp/centreon-setup"
SNMP_ETC="/etc/snmp/"
PEAR_MODULES_LIST="pear.lst"
PEAR_AUTOINST=1
INSTALL_DIR_CENTREON="/usr/share/centreon"
CENTREON_BINDIR="/usr/share/centreon/bin"
CENTREON_DATADIR="/usr/share/centreon/data"
CENTREON_USER=centreon
CENTREON_GROUP=centreon
PLUGIN_DIR="/usr/lib/nagios/plugins"
CENTREON_LOG="/var/log/centreon"
CENTREON_ETC="/etc/centreon"
CENTREON_RUNDIR="/var/run/centreon"
CENTREON_GENDIR="/var/cache/centreon"
CENTSTORAGE_RRD="/var/lib/centreon"
CENTREON_CACHEDIR="/var/cache/centreon"
CENTSTORAGE_BINDIR="/usr/share/centreon/bin"
CENTCORE_BINDIR="/usr/share/centreon/bin"
CENTREON_VARLIB="/var/lib/centreon"
CENTPLUGINS_TMP="/var/lib/centreon/centplugins"
CENTPLUGINSTRAPS_BINDIR="/usr/share/centreon/bin"
SNMPTT_BINDIR="/usr/share/centreon/bin"
CENTCORE_INSTALL_INIT=1
CENTCORE_INSTALL_RUNLVL=1
CENTSTORAGE_INSTALL_INIT=0
CENTSTORAGE_INSTALL_RUNLVL=0
CENTREONTRAPD_BINDIR="/usr/share/centreon/bin"
CENTREONTRAPD_INSTALL_INIT=1
CENTREONTRAPD_INSTALL_RUNLVL=1
CENTREON_PLUGINS=/usr/lib/centreon/plugins
INSTALL_DIR_NAGIOS="/usr/bin"
CENTREON_ENGINE_USER="centreon"
MONITORINGENGINE_USER="centreon"
MONITORINGENGINE_LOG="/var/log/centreon-engine"
MONITORINGENGINE_INIT_SCRIPT="centengine"
MONITORINGENGINE_BINARY="/usr/sbin/centengine"
MONITORINGENGINE_ETC="/etc/centreon-engine"
NAGIOS_PLUGIN="/usr/lib/nagios/plugins"
FORCE_NAGIOS_USER=1
NAGIOS_GROUP="centreon"
FORCE_NAGIOS_GROUP=1
NAGIOS_INIT_SCRIPT="/etc/init.d/centengine"
CENTREON_ENGINE_CONNECTORS="/usr/lib/centreon-connector"
BROKER_USER="centreon-broker"
BROKER_ETC="/etc/centreon-broker"
BROKER_INIT_SCRIPT="cbd"
BROKER_LOG="/var/log/centreon-broker"
SERVICE_BINARY="/usr/sbin/service"
DIR_APACHE="/etc/apache2"
DIR_APACHE_CONF="/etc/apache2/conf-available"
APACHE_CONF="apache.conf"
WEB_USER="www-data"
WEB_GROUP="www-data"
APACHE_RELOAD=1
BIN_RRDTOOL="/opt/rddtool-broker/bin/rrdtool"
BIN_MAIL="/usr/bin/mail"
BIN_SSH="/usr/bin/ssh"
BIN_SCP="/usr/bin/scp"
PHP_BIN="/usr/bin/php"
GREP="/bin/grep"
CAT="/bin/cat"
SED="/bin/sed"
CHMOD="/bin/chmod"
CHOWN="/bin/chown"
RRD_PERL="/usr/lib/perl5"
SUDO_FILE="/etc/sudoers.d/centreon"
FORCE_SUDO_CONF=1
INIT_D="/etc/init.d"
CRON_D="/etc/cron.d"
PEAR_PATH="/usr/share/php/"
PHP_FPM_SERVICE="php7.2-fpm"
PHP_FPM_RELOAD=1
DIR_PHP_FPM_CONF="/etc/php/7.2/fpm/pool.d/"
EOF
        ./install.sh -i -f /usr/local/src/centreon_engine.tmpl
        mkdir -p /usr/share/centreon/vendor
        mkdir -p /usr/{share,lib64}/centreon-engine
        mkdir -p /var/log/centreon-broker
        chown centreon-broker:centreon-broker  /var/log/centreon-broker
        chmod 775 /var/{log,lib}/centreon-broker
        cp -r /usr/local/src/centreon-web-18.10.7/vendor/* /usr/share/centreon/vendor/
        sed -i -e 's/_CENTREON_PATH_PLACEHOLDER_/centreon/g' /usr/share/centreon/www/index.html
        sed -i -e 's/#!@PHP_BIN@/#!\/usr\/bin\/php/' /usr/share/centreon/bin/centreon
        sudo a2enconf centreon
        sudo systemctl reload apache2
    popd > /dev/null

# File is not in lib64 as suggested when installing on web : /usr/lib/centreon-broker/cbmod.so

echo -e "##################################################################\n"
echo -e "##########                                              ##########\n"
echo -e "##########                    Done                      ##########\n"
echo -e "##########                                              ##########\n"
echo -e "##################################################################\n"

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0