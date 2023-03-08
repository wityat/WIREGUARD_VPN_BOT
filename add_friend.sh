#! /usr/bin/env bash
CLIENT_PRIVKEY=$( wg genkey )
CLIENT_PUBKEY=$( echo $CLIENT_PRIVKEY | wg pubkey )
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

echo "$CLIENT_PRIVKEY" >> /etc/wireguard/$1_privatekey
echo "$CLIENT_PUBKEY" >> /etc/wireguard/$1_publickey

FRIEND_NUM=$( python3 $SCRIPT_DIR/parser.py /etc/wireguard/wg0.conf )

echo "
[Peer]
PublicKey = $CLIENT_PUBKEY
AllowedIPs = 10.0.0.$FRIEND_NUM/32" >> /etc/wireguard/wg0.conf

echo "
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = 10.0.0.$FRIEND_NUM/32
DNS = 8.8.8.8

[Peer]
PublicKey = $( cat /etc/wireguard/publickey )
Endpoint = $( curl ifconfig.me ):$2
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20"  >> /etc/wireguard/$1_wg.conf

qrencode -o "/etc/wireguard/$1.png" < /etc/wireguard/$1_wg.conf
systemctl restart wg-quick@wg0.service
echo "/etc/wireguard/$1.png
/etc/wireguard/$1_wg.conf"
