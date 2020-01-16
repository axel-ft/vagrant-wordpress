#!/usr/bin/env bash

CUR_DIR=$(cd $(dirname $0) && pwd)
source "${CUR_DIR}/centreon.cfg"

NAME="Centreon Clib"
echo -e "\n##################################################################\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##########                   ${NAME}                    ##########\n"
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    wget -q "${CENTREON_CLIB}" && \
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

    wget -q "${CENTREON_PERL_CONNECTOR}" && \
    tar -xzf "${CENTREON_PERL_CONNECTOR_TGZ}"
    check $? "${NAME}" "download"

    pushd "${CENTREON_PERL_CONNECTOR_DIR}" > /dev/null
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
echo -e "\n##########                                              ##########\n"
echo -e "\n##################################################################\n"

    sudo groupadd -g 6001 centreon-engine
    sudo useradd -u 6001 -g centreon-engine -m -r -d /var/lib/centreon-engine \
        -c "Centreon-engine Admin" -s /bin/bash centreon-engine

    wget "${CENTREON_ENGINE}"
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

wget "${CENTREON_ENGINE_PLUGIN}"

tar -xzf "${CENTREON_ENGINE_PLUGIN_TGZ}"
cd nagios-plugins-2.2.1

cd
wget --no-check-certificate https://www.monitoring-plugins.org/download/monitoring-plugins-2.2.tar.gz

tar -xzf monitoring-plugins-2.2.tar.gz
cd monitoring-plugins-2.2

./configure --with-nagios-user=centreon-engine --with-nagios-group=centreon-engine --prefix=/usr/lib/nagios/plugins --libexecdir=/usr/lib/nagios/plugins --enable-perl-modules --with-openssl=/usr/bin/openssl
make 
sudo make install

cd
wget http://files.download.centreon.com/public/centreon-plugins/centreon-plugins-20191016.tar.gz
tar xzf centreon-plugins-20191016.tar.gz 
cd centreon-plugins-20191016

cd
wget http://files.download.centreon.com/public/centreon-plugins/centreon-plugins-20190704.tar.gz
tar xzf centreon-plugins-20190704.tar.gz 
cd centreon-plugins-20190704

sudo cp centreon_centreon_database.pl /usr/lib/centreon/plugins/
sudo cp centreon_mysql.pl /usr/lib/centreon/plugins/

chmod +x *
sudo mkdir -p /usr/lib/centreon/plugins
sudo mv * /usr/lib/centreon/plugins/



################################################################################
##########                                                            ##########
##########                      Centreon Broker                       ##########
##########                                                            ##########
################################################################################

sudo groupadd -g 6002 centreon-broker
sudo useradd -u 6002 -g centreon-broker -m -r -d /var/lib/centreon-broker -c "Centreon-broker Admin" -s /bin/bash centreon-broker

sudo usermod -aG centreon-broker centreon-engine

cd
wget http://files.download.centreon.com/public/centreon-broker/centreon-broker-19.10.0.tar.gz
tar xzf centreon-broker-19.10.0.tar.gz
cd centreon-broker-19.10.0

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

sudo systemctl enable cbd.service
sudo systemctl daemon-reload

################################################################################
##########                                                            ##########
##########                       SNMP Protocole                       ##########
##########                                                            ##########
################################################################################

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

################################################################################
##########                                                            ##########
##########                         MIBS                               ##########
##########                                                            ##########
################################################################################



################################################################################
##########                                                            ##########
##########                         Centreon UI                        ##########
##########                                                            ##########
################################################################################
