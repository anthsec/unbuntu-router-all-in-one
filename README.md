# Config Friendly-Core Based on Ubuntu

## 0 Introduction 

This is a project which means to create a new all-in-one system based on Friendly-R2S.

If you do not want to use OpenWrt anymore, try to config your router by yourself. This project may let you know more about how network works and get much more knowledge  of Linux.

In this project, we may config many files. For more convenience, we should better to  use ssh tools such as FinalShell with file editor instead of vim tool.

## 1 Reburn your R2S's Operation System

### 1.1 You can easily find the original FriendlyCore firmware on its website

```
https://download.friendlyelec.com/NanoPiR2S

Try to download the file bellow:
rk3328-sd-friendlycore-focal-4.19-arm64-20220125.img.zip
```

### 2.1 Reburn your SD-Card for R2S on MacOS

Windows could be much easier, so we do not introduce how to reburn sd-card on windows.

**Warning: This Step could be danger if you choose a wrong disk which is saving your Mac OS (such as Macintosh HD), please ensure you know which disk is the right one (your SD-Card).**

```bash
#Step1 Plug in your SD-Card and format it to ex-fat
#Step2 Check your disk list and find your SD-Card, remeber the name of it
diskutil list
#Step3 Unmount your disk, maybe your disk has a different name, please be careful
sudo diskutil unmount /dev/disk3s1
#Step4 Reburn the disk (SD-Card) with the new OS your downloaded just now
sudo dd bs=1m if=/Users/anthony/Desktop/rk3328-sd-friendlycore-lite-focal-5.15-arm64-20220125.img of=/dev/rdisk3
#rdisk3 = disk3s1
#Step4 could take a long time, do nothing before MAC remind you
```

Now, you successfully reburned your SD-Card, then you can plug it in your R2S and boot it.

## 2 Config network

### 2.1 Be as a DHCP client under your home gateway

Connect your Light-modem LAN and your R2S WAN with a net cable, your light-modem will distribute a local ip for R2S.

SSH Connet to R2S ( Maybe IP is 192.168.1.2)

```bash
ssh root@192.168.1.2
#default password: fa
#you need to update your apt-get
apt-get update
```

### 2.2 Config Wan Lan and ip-forward

'eth0' is default, 'eth1' needs to be created by yourself.

```file
#modify /etc/network/interfaces.d/eth0
auto eth0
allow-hotplug eth0
iface eth0 inet static

address 192.168.1.2
netmask 255.255.255.0
gateway 192.168.1.1

#add file /etc/network/interfaces.d/eth1
allow-hotplug eth1
iface eth1 inet static

address 192.168.2.1
netmask 255.255.255.0
gateway 192.168.1.2
```

Enable IP-Forward to realize WAN to LAN communication

```
#modify /etc/sysctl.conf
#Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1

#Restart network to make sure your config take effect (Maybe not necessary)
systemctl restart networking
```

### 2.3 Config your Second-Router

Second-Router can be any model of any brand. Connect your Second-Router WAN to R2S LAN.

Login Second-Router, and config WAN as static IP.

```
#Reference Configs for Second-Router are Bellow

Static IP: 192.168.2.2
Net Mask: 255.255.255.0
Gateway: 192.168.2.1
DNS1: 192.168.2.1
```

Now, you can try to ping 192.168.2.1, or 192.168.1.2. If success, your local network has been finished.

However, Second-Router could not connect to Internet yet now, because we need some more configs on R2S.

### 2.4 Config DNS with Dnsmasq

If you try "wget www.google.com", you will be informed DNS error, because based on configs above, we have not dealed with DNS server.

Built-in DNS config maybe difficult to use, we try to use Dnsmasq.

```bash
#install dnsmasq
apt-get install dnsmasq
#if your port:53 is occupied
netstat -anlp | grep -w LISTEN #find who occupy :53 (systemd-resolved)
systemctl stop systemd-resolved #stop systemd-resolved
systemctl disable systemd-resolved #systemd-resolved will not launch with boot anymore
#reintall dnsmasq
apt-get install dnsmasq
```

```
#config dnsmasq
#modify /run/resolvconf/resolv.conf
nameserver 127.0.0.1

#modify /etc/dnsmasq.d/mydns.conf
#add servers bellow
server="114.114.114.114"
server="8.8.8.8"

#modify /etc/dnsmasq.conf
addn-hosts=/etc/hosts #make your own 'hosts' available in local network
```

```bash
#make sure dnsmasq status
systemctl status dnsmasq #check the status of dnsmasq
systemctl enable dnsmasq #launch with boot
reboot #reboot systeml

#if you want to restart dnsmasq
systemctl restart dnsmasq
```

After reboot, try ping, if all success, you configed all the items right till now.

```
 ping -I 192.168.2.1 www.google.com
 ping -I 192.168.1.2 www.google.com
 ping -I 192.168.1.2 192.168.2.1
 ping -I 192.168.2.1 192.168.1.2
```

### 2.5 Second-Router Connect to Internet

Your R2S is now on Internet, but your Sencod-Router not. This section will solve this problem.

```bash
#install iptables 
apt-get install iptables

#Core sentence
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#config above will be invalid after reboot, use this app below
sudo apt-get install iptables-persistent -y
```

This chapter is over, you can now use the basic router function on R2S.

In the next chapter, we will try to install clash for linux release and take more config, it could be more complex, please be always patient.

## 3 Clash for Linux Router

In this chapter, we don't introduce how to use the basic function of Clash for Linux, but we research how to establish a **Transparent Proxy** via Clash. If success, you can use all the devices under local network to visit the websites you cannot visit before.

### 3.1 Install Clash for Linux

```bash
#wget Clash Release from https://github.com/Dreamacro/clash/releases
wget https://github.com/Dreamacro/clash/releases/download/v1.10.0/clash-linux-armv8-v1.10.0.gz
#unzip
gzip -d clash-linux-xxxxx.gz
#move to usr/bin and rename its name to "clash"
sudo mv clash-linux-amd64-v0.19.0 /usr/bin/clash
#it's not necessary to give run permission but you can do it
sudo chmod +x /usr/bin/clash
#check if success
clash -v 
#config start with boot
#modify or create /etc/systemd/system/clash.service
[Unit]
Description=clash for linux

[Service]
Type=simple
User=root
ExecStart=/usr/bin/clash -d /root/.config/clash/
Restart=on-failure

[Install]
WantedBy=multi-user.target

#reload systemd daemon
systemctl daemon-reload
#use stop/start/restart/enable/disable to replace [***] below
systemctl [***] clash


```

### 3.2 Config YAML

```yaml
port: 7890
socks-port: 7891
redir-port: 7892
allow-lan: true
mode: rule
log-level: info
external-ui: dashboard # in "/root/.config/clash/dashboard", such as YACD
external-controller: '0.0.0.0:9090' # url:"http://0.0.0.0:9090/ui"
secret: '' #password to login dashboard, it's not necessary
cfw-latency-url: 'http://cp.cloudflare.com/generate_204'

#redir-host mode, you have to enable your DNS config.
#how clash to work refer to https://blog.skk.moe/post/what-happend-to-dns-in-proxy/
dns:
  enable: true # enable	customize dns
  ipv6: false # default is false
  listen: 0.0.0.0:1053 #remember it, we use 1053 port soon
  enhanced-mode: redir-host  #another mode is fake-ip
  #fake-ip-range: 198.18.0.1/16 # if you don't know what it is, don't change it
  nameserver:
    - 127.0.0.1:53 # Your Dnsmasq
  fallback:
    - 208.67.220.220:5353 #fallback1
    - 208.67.222.222:5353 #fallback2
    - 101.6.6.6:5353 #fallback3
proxies:
#Your subscription
```

### 3.3 Config Iptables

```bash
#clean or iptables nat rules
iptables -t nat -F

#config iptables
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
#add udp
iptables -t nat -A Clash -p udp -j REDIRECT --to-ports 7892

iptables -t nat -A PREROUTING -p tcp -j Clash

iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j DNAT --to-destination 192.168.2.1:1053

```



## 4 Docker install Apps

```
Try it by yourself.
```



## 5 References

```
[Install Clash] https://github.com/yuanlam/Clash-Linux
[Dnsmasq] https://cloud.tencent.com/developer/article/1174717
...
```

