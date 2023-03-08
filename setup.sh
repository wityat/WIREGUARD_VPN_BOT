#!/usr/bin/env bash
apt update -y && apt upgrade -y
apt install -y wireguard
apt install curl qrencode supervisor -y


PORT="51829"
WORKDIR="/etc/wireguard/"
SUPERVISOR_BOT_CONF_FILE="/etc/supervisor/conf.d/bot.conf"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)


cd $WORKDIR
wg genkey | tee $WORKDIR/privatekey | wg pubkey | tee $WORKDIR/publickey
chmod 600 $WORKDIR/privatekey
wg genkey | tee $WORKDIR/f_privatekey | wg pubkey | tee $WORKDIR/f_publickey
echo "
[Interface]
PrivateKey = $( cat $WORKDIR/privatekey )
Address = 10.0.0.1/24
ListenPort = $PORT
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE

[Peer]
PublicKey = $( cat $WORKDIR/f_publickey )
AllowedIPs = 10.0.0.1/32" >> $WORKDIR/wg0.conf

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

if [[ $( sysctl -p ) == "net.ipv4.ip_forward = 1" ]]; then
    echo "IP Forwarding enabled."
else
    echo "ERROR OCCURRED, ip forwarding is not enabled"
fi

systemctl enable wg-quick@wg0.service
systemctl stop wg-quick@wg0.service
systemctl start wg-quick@wg0.service
echo "Started service"

sudo supervisord
sudo service supervisor start

sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
echo -ne '\n' | sudo apt install python3.8
sudo apt install python3-pip -y
apt install python3.8-venv
python3.8 -m venv $WORKDIR/venv
source /etc/wireguard/venv/bin/activate && pip install -r $SCRIPT_DIR/requirements.txt
sudo chmod 777 $SCRIPT_DIR/add_friend.sh
echo "
[program:bot]
command=/bin/bash -c 'source $WORKDIR/venv/bin/activate && python bot.py'
directory=$SCRIPT_DIR
autostart=true
autorestart=true
stdout_logfile=/var/log/server.log
stderr_logfile=/var/log/server_error.log
user=root" >> $SUPERVISOR_BOT_CONF_FILE

sudo service supervisor stop
sudo service supervisor start
sudo service supervisor restart

echo "Bot started"