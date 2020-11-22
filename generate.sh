#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin; export PATH
########
# usage: bash <(curl -s https://raw.githubusercontent.com/mixool/shadowrocket-rules/main/generate.sh) category-porn
#######

# tempfile & rm it when exit
trap 'rm -f "$TMPFILE"' EXIT; TMPFILE=$(mktemp) || exit 1

function domainlist(){
    # show v2fly/domain-list-community domains
    wget -qO- "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/$1" | grep -oE "^[a-zA-Z0-9./-].*" | sed -e "s/#.*//g" -e "s/@.*//g" >$TMPFILE
    includelistcn=$(cat $TMPFILE | grep -oE "include:.*" | cut -f2 -d: | tr "\n" " ") && sed -i -e "s/^include:.*//g" -e "s/^regexp:.*//g" -e "s/^full://g" -e "s/#.*//g" -e "s/@.*//g" $TMPFILE
    while [[ "$includelistcn" != "" ]]; do
        for list in $includelistcn; do
            wget -qO- "https://raw.githubusercontent.com/v2fly/domain-list-community/master/data/$list" | grep -oE "^[a-zA-Z0-9./-].*" | sed "s/#.*//g" >>$TMPFILE
        done
        includelistcn=$(cat $TMPFILE | grep -oE "include:.*" | cut -f2 -d: | tr "\n" " ") && sed -i -e "s/^include:.*//g" -e "s/^regexp:.*//g" -e "s/^full://g" -e "s/#.*//g" -e "s/@.*//g" $TMPFILE
    done
    cat $TMPFILE | sort -u | sed "s/[[:space:]]//g" |sed "/^$/d"
}

function allrocket(){
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
# Site: https://github.com/mixool/shadowrocket-rules
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
# reject-list category-ads-all
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,Reject/' | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# direct-list cn
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt | sed "s/^/DOMAIN-SUFFIX,&/" | sed "s/$/&,DIRECT/" | sed "s/DOMAIN-SUFFIX,regexp/URL-REGEX/")

# IP-CIDR LAN
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT

# FINAL
GEOIP,CN,DIRECT
FINAL,PROXY

[Host]
localhost = 127.0.0.1

[URL Rewrite]
^http://(www.)?g.cn https://www.google.com 302
^http://(www.)?google.cn https://www.google.com 302
EOF

cat $TMPFILE
}

case $1 in
    allrocket)
        allrocket
        ;;
    *)
        domainlist $1
esac
