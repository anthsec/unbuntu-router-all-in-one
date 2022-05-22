#!/bin/bash
systemctl stop clash.service
iptables -t nat -F


iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -N Clash

iptables -t nat -A Clash -d 0.0.0.0/8 -j RETURN
iptables -t nat -A Clash -d 10.0.0.0/8 -j RETURN
iptables -t nat -A Clash -d 127.0.0.0/8 -j RETURN
iptables -t nat -A Clash -d 169.254.0.0/16 -j RETURN
iptables -t nat -A Clash -d 172.16.0.0/12 -j RETURN
iptables -t nat -A Clash -d 192.168.0.0/16 -j RETURN
iptables -t nat -A Clash -d 224.0.0.0/4 -j RETURN
iptables -t nat -A Clash -d 240.0.0.0/4 -j RETURN

iptables -t nat -A Clash -p tcp -j REDIRECT --to-ports 7892
#add udp proxy
iptables -t nat -A Clash -p udp -j REDIRECT --to-ports 7892

iptables -t nat -A PREROUTING -p tcp -j Clash

iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.2.1:1053


systemctl start clash.service
