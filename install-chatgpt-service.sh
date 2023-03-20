#!/bin/bash

# parse command line arguments
# the arguments has port-range and password and encryption method
# print usage if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 port-range password encryption-method"
    exit 1
fi

# parse port range
port_range=$1
# port_range must be in the format of 10000-20000
# if port_range is not in the format, use 10000-20000 as default
if [[ $port_range != *-* ]]; then
    port_range="10000-20000"
fi
# echo "port range: $port_start - $port_end"
echo "port range: $port_range"
# parse password
password=$2
echo "password: $password"
# parse encryption method
method=$3
# method must be one of the following
# aes-128-cfb, aes-192-cfb, aes-256-cfb, aes-128-ctr, aes-192-ctr, aes-256-ctr, camellia-128-cfb, camellia-192-cfb, camellia-256-cfb, bf-cfb, cast5-cfb, des-cfb, rc4-md5, chacha20, salsa20, rc4
# if method is not one of the above, use aes-256-gcm as default
if [[ $method != "aes-128-cfb" && $method != "aes-192-cfb" && $method != "aes-256-cfb" && $method != "aes-128-ctr" && $method != "aes-192-ctr" && $method != "aes-256-ctr" && $method != "camellia-128-cfb" && $method != "camellia-192-cfb" && $method != "camellia-256-cfb" && $method != "bf-cfb" && $method != "cast5-cfb" && $method != "des-cfb" && $method != "rc4-md5" && $method != "chacha20" && $method != "salsa20" && $method != "rc4" ]]; then
    method="aes-256-gcm"
fi
echo "encryption method: $method"

# Install dependencies
sudo apt-get update
sudo apt-get install -y wget git build-essential autoconf libtool libssl-dev

# Install Shadowsocks-libev use apt-get
sudo apt-get install -y shadowsocks-libev

# generate shadowsocks-libev server configuration file
cat <<EOF > /tmp/config.json
{
    "server":"127.0.0.1",
    "server_port":8388,
    "password":"$password",
    "method":"$method"
}
EOF
sudo mv /tmp/config.json /etc/shadowsocks-libev/config.json

# Install Kcptun
wget https://github.com/xtaci/kcptun/releases/download/v20230214/kcptun-linux-amd64-20230214.tar.gz
tar -xvf kcptun-linux-amd64-20230214.tar.gz
sudo mv server_linux_amd64 /usr/local/bin/kcptun-server
sudo chmod +x /usr/local/bin/kcptun-server

# Install supervisord
sudo apt-get install -y supervisor

# Configure Shadowsocks-libev to run under supervisord
cat <<EOF > /tmp/shadowsocks-libev.conf
[program:shadowsocks-libev]
command=/usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json
user=root
autostart=true
autorestart=true
redirect_stderr=true
EOF
sudo mv /tmp/shadowsocks-libev.conf /etc/supervisor/conf.d/shadowsocks-libev.conf

# Configure Kcptun to run under supervisord
cat <<EOF > /tmp/kcptun-server.conf
[program:kcptun-server]
command=/usr/local/bin/kcptun-server -l :$port_range -t "127.0.0.1:8388"
user=root
autostart=true
autorestart=true
redirect_stderr=true
EOF

sudo mv /tmp/kcptun-server.conf /etc/supervisor/conf.d/kcptun-server.conf

# Reload supervisord configuration
sudo supervisorctl reread
sudo supervisorctl update
