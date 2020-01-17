cd /tmp && wget --progress=bar:force  https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
cd ../etc && tar xvf ../tmp/EasyRSA-3.0.4.tgz
cd EasyRSA-3.0.4
cp vars.example vars
cat << 'VARS' > /etc/EasyRSA-3.0.4/vars
if [ -z "$EASYRSA_CALLER" ]; then
        echo "You appear to be sourcing an Easy-RSA 'vars' file." >&2
        echo "This is no longer necessary and is disallowed. See the section called" >&2
        echo "'How to use this file' near the top comments for more details." >&2
        return 1
fi

set_var EASYRSA_REQ_COUNTRY    "FR"
set_var EASYRSA_REQ_PROVINCE   "Ile-de-France"
set_var EASYRSA_REQ_CITY       "Nanterre"
set_var EASYRSA_REQ_ORG        "OpensourceCertificat"
set_var EASYRSA_REQ_EMAIL      "admin@opensource.fr"
set_var EASYRSA_REQ_OU         "Opensource"

VARS
echo "[###                        ] Init PKI"
/etc/EasyRSA-3.0.4/easyrsa init-pki
echo 'set_var EASYRSA_REQ_CN "CN_CA"' >> vars
/etc/EasyRSA-3.0.4/easyrsa build-ca nopass
cd /etc/EasyRSA-3.0.4/
echo "[######                     ] Gen req server & sign"
sed -i 's/set_var EASYRSA_REQ_CN "CN_CA"/set_var EASYRSA_REQ_CN "CN_server" /g' vars

./easyrsa --batch gen-req server nopass
./easyrsa --batch sign-req server server
cp pki/ca.crt /etc/openvpn
cp pki/issued/server.crt /etc/openvpn

echo "[#########                  ] Gen req ta & dh"
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp ta.key /etc/openvpn 
cp pki/dh.pem /etc/openvpn
cp pki/private/server.key /etc/openvpn/

echo "[############               ] Gen & sign client req"
sed -i 's/set_var EASYRSA_REQ_CN "CN_server"/set_var EASYRSA_REQ_CN "CN_Client1"/g' vars
./easyrsa --batch gen-req client1 nopass
./easyrsa --batch sign-req client client1
sed -i 's/set_var EASYRSA_REQ_CN "CN_Client1"/set_var EASYRSA_REQ_CN "CN_Client2"/g' vars
./easyrsa --batch gen-req client2 nopass
./easyrsa --batch sign-req client client2

echo "[###############            ] Add to config directory"
mkdir -p ../clients-configs/keys
cp ta.key ../clients-configs/keys
cp pki/ca.crt ../clients-configs/keys
cp pki/private/client1.key ../clients-configs/keys
cp pki/issued/client1.crt ../clients-configs/keys
cp pki/private/client2.key ../clients-configs/keys
cp pki/issued/client2.crt ../clients-configs/keys

echo "[##################         ] Service config"
cd ../../
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
gzip -d /etc/openvpn/server.conf.gz
sed -i 's/;tls-auth ta.key 0 # This file is secret/tls-auth ta.key 0 # This file is secret /g' etc/openvpn/server.conf
sed -i 's/;cipher AES-256-CBC/cipher AES-256-CBC /g' etc/openvpn/server.conf
sed -i 's/dh dh2048.pem/dh dh.pem /g' etc/openvpn/server.conf
echo -e '\nauth SHA256' >> etc/openvpn/server.conf
sed -i 's/;user nobody/user nobody /g' etc/openvpn/server.conf
sed -i 's/;group nogroup/group nogroup /g' etc/openvpn/server.conf


echo "[#####################      ] IP4 forward & iptables"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' etc/sysctl.conf

echo "[########################   ] Enable service"
systemctl start openvpn@server 
systemctl enable openvpn@server

echo "[###########################] End config & create opvpn files"
mkdir -p etc/clients-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/clients-configs/base.conf
sed -i 's/remote my-server-1 1194/remote 192.168.33.16 1194/g' etc/clients-configs/base.conf
sed -i 's/ca.crt/#ca.crt/g' etc/clients-configs/base.conf
sed -i 's/cert client.crt/#cert client.crt/g' etc/clients-configs/base.conf
sed -i 's/key client.key/#key client.key/g' etc/clients-configs/base.conf
sed -i 's/tls-auth ta.key 1/#tls-auth ta.key 1/g' etc/clients-configs/base.conf
sed -i 's/;user nobody/user nobody /g' etc/clients-configs/base.conf
sed -i 's/;group nogroup/group nogroup /g' etc/clients-configs/base.conf
echo -e '\nauth SHA256\nkey-direction 1\n# script-security 2\n# up /etc/openvpn/update-resolv-conf\n# down /etc/openvpn/update-resolv-conf' >> etc/clients-configs/base.conf
cat << 'SCRIPT' >  etc/clients-configs/make_config.sh
#!/bin/bash

# First argument: Client identifier

KEY_DIR=etc/clients-configs/keys
OUTPUT_DIR=etc/clients-configs/files
BASE_CONFIG=etc/clients-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn

SCRIPT
chmod 700 etc/clients-configs/make_config.sh
sudo etc/clients-configs/make_config.sh client1
sudo etc/clients-configs/make_config.sh client2