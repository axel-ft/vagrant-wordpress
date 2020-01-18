#!/bin/bash

################################################################################################################
# iptables.sh - Common iptables rules applied to all the virtual machines in this project                      #
# Usage : ./iptables.sh [current_progress]                                                                     #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

# All rules must be set once for IPv4 and once for IPv4 with the dedicated commands iptables et ip6tables

# Empty all existing configuration of iptables
iptables -F
ip6tables -F
iptables -N ICMPRULES
ip6tables -N ICMPRULES

# Set rules to prevent ping flood (ICMP protocol)
# IPv4
iptables -A ICMPRULES -m recent --name ICMP --set --rsource
iptables -A ICMPRULES -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -m limit --limit 1/sec --limit-burst 1 -j LOG --log-prefix "iptables[ICMP-flood]: "
iptables -A ICMPRULES -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -j DROP
iptables -A ICMPRULES -j ACCEPT
# IPv6
ip6tables -A ICMPRULES -m recent --name ICMP --set --rsource
ip6tables -A ICMPRULES -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -m limit --limit 1/sec --limit-burst 1 -j LOG --log-prefix "iptables[ICMP-flood]: "
ip6tables -A ICMPRULES -m recent --name ICMP --update --seconds 1 --hitcount 6 --rsource --rttl -j DROP
ip6tables -A ICMPRULES -j ACCEPT

# Define input rules
# IPv4
iptables -A INPUT -i lo -j ACCEPT                                                                      # Allow trafic on lo
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT                                 # Do not disrupt existing conneections
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP                                               # Drop TCP Invalid
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP                                                  # Drop TCP No flags
iptables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP                                    # Prevent SYN flood
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP                                                   # Drop TCP All flags
iptables -A INPUT -p icmp --icmp-type 0  -m conntrack --ctstate NEW -j ACCEPT                          # ICMP type 0
iptables -A INPUT -p icmp --icmp-type 3  -m conntrack --ctstate NEW -j ACCEPT                          # ICMP type 3
iptables -A INPUT -p icmp --icmp-type 8  -m conntrack --ctstate NEW -j ICMPRULES                       # ICMP type 8 rate limited
iptables -A INPUT -p icmp --icmp-type 11 -m conntrack --ctstate NEW -j ACCEPT                          # ICMP type 11
iptables -A INPUT -i eth0 -p tcp --dport ssh -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT          # New SSH on Vagrant network card
iptables -A INPUT -p tcp --sport domain -m conntrack --ctstate ESTABLISHED -j ACCEPT                   # DNS (TCP)
iptables -A INPUT -p udp -m multiport --sports domain,ntp -m conntrack --ctstate ESTABLISHED -j ACCEPT # DNS and NTP (UDP)
# IPv6
ip6tables -A INPUT -i lo -j ACCEPT                                                                      # Allow trafic on lo
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT                                 # Do not disrupt existing connections
ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP                                               # Drop TCP Invalid
ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP                                                  # Drop TCP No flags
ip6tables -A INPUT -p tcp ! --syn -m conntrack --ctstate NEW -j DROP                                    # Drop New TCP without SYN flag only
ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP                                                   # Drop TCP All flags
ip6tables -A INPUT -p icmpv6 --icmpv6-type 0  -m conntrack --ctstate NEW -j ACCEPT                      # ICMP type 0
ip6tables -A INPUT -p icmpv6 --icmpv6-type 3  -m conntrack --ctstate NEW -j ACCEPT                      # ICMP type 3
ip6tables -A INPUT -p icmpv6 --icmpv6-type 8  -m conntrack --ctstate NEW -j ICMPRULES                   # ICMP type 8 rate limited
ip6tables -A INPUT -p icmpv6 --icmpv6-type 11 -m conntrack --ctstate NEW -j ACCEPT                      # ICMP type 11
ip6tables -A INPUT -i eth0 -p tcp --dport ssh -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                  # New SSH
ip6tables -A INPUT -p tcp --sport domain -m conntrack --ctstate ESTABLISHED -j ACCEPT                   # DNS (TCP)
ip6tables -A INPUT -p udp -m multiport --sports domain,ntp -m conntrack --ctstate ESTABLISHED -j ACCEPT # DNS and NTP (UDP)

# Define output rules
# IPv4
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT                                     # Do not disrupt existing connections
iptables -A OUTPUT -m conntrack --ctstate INVALID -j DROP                                                   # Drop TCP Invalid
iptables -A OUTPUT -o eth0 -p tcp --sport ssh -m conntrack --ctstate ESTABLISHED -j ACCEPT                          # Established SSH
iptables -A OUTPUT -p tcp --dport domain -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                   # Allow DNS resolution (TCP)
iptables -A OUTPUT -p udp -m multiport --dports domain,ntp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow DNS resolution and NTP (UDP)
# IPv6
ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT                                     # Do not disrupt existing connections
ip6tables -A OUTPUT -m conntrack --ctstate INVALID -j DROP                                                   # Drop TCP Invalid
ip6tables -A OUTPUT -o eth0 -p tcp --sport ssh -m conntrack --ctstate ESTABLISHED -j ACCEPT                  # Established SSH
ip6tables -A OUTPUT -p tcp --dport domain -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                   # Allow DNS resolution (TCP)
ip6tables -A OUTPUT -p udp -m multiport --dports domain,ntp -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT # Allow DNS resolution and NTP (UDP)

# Define default policies
# IPv4
iptables -P INPUT DROP    # Drop all by default
iptables -P FORWARD DROP  # Drop all by default
iptables -P OUTPUT ACCEPT # Accept by default (troubles with drop policy)
# IPv6
ip6tables -P INPUT DROP   # Drop all by default
ip6tables -P FORWARD DROP # Drop all by default
ip6tables -P OUTPUT DROP  # Drop all by default

# Save rules in case of no modification in custom script (defined for each machine)
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Display progress bar if command is in path and current progress in provisioning given
which progressbar 2>&1>/dev/null && [ ${1} ] && progressbar ${1}
exit 0