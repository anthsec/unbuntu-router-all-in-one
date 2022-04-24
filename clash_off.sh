#!/bin/bash
systemctl stop clash.service
iptables -t nat -F

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE