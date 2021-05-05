#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin; export PATH
#######
# usage: bash <(curl -s https://raw.githubusercontent.com/mixool/rules/main/generate.sh) category-porn
######

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
    cat $TMPFILE | sort -u | sed "s/[[:space:]]//g" | sed "/^$/d"
}

function allrocket(){
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date +%Y-%m-%d\ %T)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false
update-url = https://raw.githubusercontent.com/mixool/rules/main/allrocket.conf

[Rule]
#DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/reject.list,REJECT
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/direct.list,DIRECT
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/apple-cn.list,DIRECT
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/google-cn.list,DIRECT
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/gfw.list,PROXY
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/greatfire.list,PROXY
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/proxy.list,PROXY
IP-CIDR,91.108.4.0/22,PROXY,no-resolve
IP-CIDR,91.108.8.0/22,PROXY,no-resolve
IP-CIDR,91.108.12.0/22,PROXY,no-resolve
IP-CIDR,91.108.16.0/22,PROXY,no-resolve
IP-CIDR,91.108.56.0/22,PROXY,no-resolve
IP-CIDR,109.239.140.0/24,PROXY,PROXY
IP-CIDR,149.154.160.0/20,PROXY,no-resolve
IP-CIDR,2001:b28:f23d::/48,PROXY,no-resolve
IP-CIDR,2001:b28:f23f::/48,PROXY,no-resolve
IP-CIDR,2001:67c:4e8::/48,PROXY,no-resolve
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT
GEOIP,CN,DIRECT
FINAL,PROXY

[Host]
localhost = 127.0.0.1

[URL Rewrite]
^http://(www.)?(g|google).cn https://www.google.com 302
EOF

cat $TMPFILE
}

function allgeocn(){
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date +%Y-%m-%d\ %T)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false
update-url = https://raw.githubusercontent.com/mixool/rules/main/allgeocn.conf

[Rule]
DOMAIN-SET,https://raw.githubusercontent.com/mixool/rules/main/domainset/direct.list,DIRECT
RULE-SET,https://cdn.jsdelivr.net/gh/soffchen/GeoIP2-CN@release/surge-ruleset.list,DIRECT
RULE-SET,https://raw.githubusercontent.com/soffchen/GeoIP2-CN/release/surge-ruleset.list,DIRECT
GEOIP,CN,DIRECT
FINAL,PROXY

[Host]
localhost = 127.0.0.1

[URL Rewrite]
^http://(www.)?(g|google).cn https://www.google.com 302
EOF

cat $TMPFILE
}

function cnlist_autoswitch(){
    cat <<EOF >$TMPFILE
[AutoProxy]
! Last Modified: $(date +%Y-%m-%d\ %T.%s) $(date +%z) UTC
! Expires: 24h
! HomePage: https://github.com/mixool/rules
! GitHub URL: https://raw.githubusercontent.com/mixool/rules/main/autoswitchcnlist.txt
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt | sed "s/^/||&/" | sed "/||regexp:.*/d" | sed "/^$/d")
EOF

cat $TMPFILE
}

function proxylist_autoswitch(){
    cat <<EOF >$TMPFILE
[AutoProxy]
! Last Modified: $(date +%Y-%m-%d\ %T.%s) $(date +%z) UTC
! Expires: 24h
! HomePage: https://github.com/mixool/rules
! GitHub URL: https://raw.githubusercontent.com/mixool/rules/main/autoswitchproxylist.txt
$(wget -qO- https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt | sed "s/^/||&/" | sed "/||regexp:.*/d" | sed "/^$/d")
EOF

cat $TMPFILE
}

case $1 in
    allrocket)
        allrocket
        ;;
    allgeocn)
        allgeocn
        ;;
    cnlist_autoswitch)
        cnlist_autoswitch
        ;;
    proxylist_autoswitch)
        proxylist_autoswitch
        ;;
    *)
        domainlist $1
esac
