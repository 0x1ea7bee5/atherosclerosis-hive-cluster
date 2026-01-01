#!/bin/bash
# Basic shell script to configure my head node for compute cluster management.
# Likely to be expanded into a bloated script of hate and agony
# Basic steps of setup:
#
# # # 1. Wired LAN iface config
# # # 2. DHCP config for basic comms
# # # 3. Ansible Config
# # # # 3.a. Basic network config DHCP -> Static 
#

WIRED_IFACE="eno1"
WIRED_IP="172.69.69.0"
WIRED_NETMASK="255.255.255.0"

DHCP_DEF_P="/etc/default/isc-dhcp-server"
DHCP_CONF_P="/etc/dhcp/dhcpd.conf"
WIRED_DHCP_START="172.69.69.2"
WIRED_DHCP_STOP="172.69.69.254"
WIRED_BROADCAST="172.69.69.255"

## 1. Wired LAN iface config
ip link set $WIRED_IFACE down

echo "Beginning Interface config for $WIRED_IFACE"

CFG_PATH="/etc/network/interfaces.d"
CFG_FNAME="ifcfg-${WIRED_IFACE}"
CFG_FULLPATH="$CFG_PATH/$CFG_FNAME"
echo $CFG_FULLPATH

if [ -f "$CFG_FULLPATH" ]; then
	echo "Config file $CFG_FULLPATH already exists. Overriding existing file"
	
else
	echo "Config file $CFG_FULLPATH was not found. Creating new file"
	touch $CFG_FULLPATH
fi
echo "Modifying file $CFG_FULLPATH"


cat <<EOF > "$CFG_FULLPATH"
###### THIS FILE WAS GENERATED WITH THE HEAD NODE CONFIG SCRIPT
auto $WIRED_IFACE
iface $WIRED_IFACE inet static
	address $WIRED_IP
	netmask $WIRED_NETMASK
EOF
ip link set $WIRED_IFACE up

## 2. DHCP initial setup
echo "Begin DHCP setup"
apt install isc-dhcp-server -y
# now add the wired iface for the dhcp config
sed -i "/INTERFACESv4/c\INTERFACESv4=\"$WIRED_IFACE\""  $DHCP_DEF_P

# completely override and nuke existing config because yolo i guess
cat <<EOF > "$DHCP_CONF_P"
###### THIS FILE WAS GENERATED WITH THE HEAD NODE CONFIG SCRIPT
subnet $WIRED_IP netmask $WIRED_NETMASK {
	range $WIRED_DHCP_START $WIRED_DHCP_STOP;
	option domain-name "hive.ass";
	default-lease-time 600;
	max-lease-time 7200;
	option broadcast-address $WIRED_BROADCAST;

}
EOF

# start the service
echo "Starting DHCP"
#systemctl stop isc-dhcp-server.service
systemctl start isc-dhcp-server.service
