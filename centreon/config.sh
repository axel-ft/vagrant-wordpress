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

CENTREON_CLIB="http://files.download.centreon.com/public/centreon-clib/centreon-clib-18.10.0.tar.gz"
CENTREON_CLIB_TGZ="centreon-clib-18.10.0.tar.gz"
CENTREON_CLIB_DIR="centreon-clib-18.10.0/build"

CENTREON_PERL_CONNECTOR="http://files.download.centreon.com/public/centreon-connectors/centreon-connectors-18.10.0.tar.gz"
CENTREON_PERL_CONNECTOR_TGZ="centreon-connectors-18.10.0.tar.gz"
CENTREON_PERL_CONNECTOR_DIR="centreon-connector-18.10.0/perl/build"

CENTREON_SSH_CONNECTOR_DIR="centreon-connector-18.10.0/ssh/build"

CENTREON_ENGINE="http://files.download.centreon.com/public/centreon-engine/centreon-engine-18.10.0.tar.gz"
CENTREON_ENGINE_TGZ="centreon-engine-18.10.0.tar.gz"
CENTREON_ENGINE_DIR="centreon-engine-18.10.0/build"
/tmp/centreon-engine-18.10.0/centreon-engine-18.10.0

NAGIOS_PLUGIN="http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz"
NAGIOS_PLUGIN_TGZ="nagios-plugins-2.2.1.tar.gz"

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

cd /tmp


NAME="Centreon Clib"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    wget --progress=bar:force "${CENTREON_CLIB}" && \
    tar -xzf "${CENTREON_CLIB_TGZ}"
    check $? "${NAME}" "download"

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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"


NAME="Centreon Perl Connector "
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    wget --progress=bar:force "${CENTREON_PERL_CONNECTOR}" && \
    tar -xzf "${CENTREON_PERL_CONNECTOR_TGZ}"
    check $? "${NAME}" "download"

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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"


NAME="Centreon SSH Connector"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"


NAME="Centreon Engine"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"²²
echo -e "\n##################################################################\n"

    sudo groupadd -g 6001 centreon-engine
    sudo useradd -u 6001 -g centreon-engine -m -r -d /var/lib/centreon-engine \
        -c "Centreon-engine Admin" -s /bin/bash centreon-engine

    wget --progress=bar:force "${CENTREON_ENGINE}"
    tar -xzf "${CENTREON_ENGINE_TGZ}" 
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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="Centreon Engine Plugins"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    wget --progress=bar:force "${CENTREON_ENGINE_PLUGIN}"
    tar -xzf "${CENTREON_ENGINE_PLUGIN_TGZ}"
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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="Centreon Engine Plugins"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    wget --progress=bar:force "${NAGIOS_PLUGIN}"
    tar -xzf "${NAGIOS_PLUGIN_TGZ}"

    wget --progress=bar:force --no-check-certificate "${MONITORING_PLUGINS}"

    tar -xzf "${MONITORING_PLUGINS_TGZ}"
    pushd "${MONITORING_PLUGINS_DIR}" > /dev/null
    ./configure --with-nagios-user=centreon-engine --with-nagios-group=centreon-engine --prefix=/usr/lib/nagios/plugins --libexecdir=/usr/lib/nagios/plugins --enable-perl-modules --with-openssl=/usr/bin/openssl
    make 
    sudo make install
    popd > /dev/null

    wget --progress=bar:force "${CENTREON_PLUGINS}"
    tar -xzf "${CENTREON_PLUGINS_TGZ}" 
    pushd "${CENTREON_PLUGINS_DIR}" > /dev/null
        chmod +x *
        sudo mkdir -p /usr/lib/centreon/plugins
        sudo mv * /usr/lib/centreon/plugins/
    popd > /dev/null

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="Centreon Broker"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    sudo groupadd -g 6002 centreon-broker
    sudo useradd -u 6002 -g centreon-broker -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" -s /bin/bash centreon-broker

    sudo usermod -aG centreon-broker centreon-engine


    wget --progress=bar:force "${CENTREON_BROKER}"
    tar -xzf "${CENTREON_BROKER_TGZ}"
    pushd "${CENTREON_BROKER_DIR}" > /dev/null
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

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="SNMP Protocole"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

cat << SNMPD > /etc/snmp/snmpd.conf
agentAddress udp:localhost:161
rocommunity public localhost

trapsink        localhost       public
SNMPD

cat << SYSLOG > /etc/default/snmpd
# snmpd options (use syslog, close stdin/out/err).
SNMPDOPTS='-LS4d -Lf /dev/null -u snmp -g snmp -I -smux,mteTrigger,mteTriggerConf -p /var/run/snmpd.pid'
.....
SYSLOG

cat << TRAPD > /etc/default/snmptrapd
.....
TRAPDRUN=yes

# snmptrapd options (use syslog).
TRAPDOPTS='-On -Lsdf /var/log/snmptrapd.log -p /run/snmptrapd.pid'
.....
TRAPD

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="MIBS"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    export MIBDIRS=/usr/shaqre/MIBS
    export MIBS=ALL

cat << SNMP > /etc/snmp/snmp.conf
#mibs ALL 
SNMP

    sudo systemctl restart snmpd
    sudo systemctl restart snmptrapd

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

NAME="Centreon UI"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    sudo groupadd -g 6000 centreon
    sudo useradd -u 6000 -g centreon -m -r -d /var/lib/centreon -c "Centreon Admin" -s /bin/bash centreon

    sudo usermod -aG centreon centreon-broker

    sudo a2enmod proxy_fcgi setenvif proxy rewrite
    sudo a2enconf php7.2-fpm
    sudo a2dismod php7.2
    sudo systemctl restart apache2 php7.2-fpm

# Nouveauté avec la version 19.10.x, il faut obligatoirement configurer le paramètre date.timezone pour le php-fpm. Pour cela, éditez le fichier de configuration pour apache. Attention, bien respectez la casse et ne pas mettre d'espace.
# sudo vi /etc/php/7.3/fpm/php.ini
# Saisissez la valeur adaptée à votre configuration.
# [Date]
# ; Defines the default timezone used by the date functions
# ; http://php.net/date.timezone
# date.timezone = Europe/Paris


    wget --progress=bar:force "${CENTREON_UI}"
    tar -xzf "${CENTREON_UI_TGZ}"
    pushd "${CENTREON_UI_DIR}"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
        composer install --no-dev --optimize-autoloader
    popd > /dev/null

    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
    sudo apt-get install -y nodejs

    sudo npm install
    sudo npm run build

# sudo bash ./install.sh -i - test 

echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                    Done                      ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${3} ] && progressbar ${3}
exit 0