#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin; export PATH
########

# tempfile & rm it when exit
trap 'rm -f "$TMPFILE"' EXIT; TMPFILE=$(mktemp) || exit 1

# 生成指定域名列表 | 暂时无法使用regexp匹配
function domainlist(){
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

# 生成白名单配置文件 cn
function whitelistconf(){
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
$(domainlist cn | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,DIRECT/')
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT
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

# 生成白名单+屏蔽广告配置文件
function whitelistplusconf(){
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
$(domainlist category-ads-all | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,Reject/')
$(domainlist cn | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,DIRECT/')
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT
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

# 生成黑名单配置文件 geolocation-!cn by gfwlist
function gfwlistconf(){
    gfwlist_url="https://raw.githubusercontent.com/v2fly/domain-list-community/release/gfwlist.txt"
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
$(wget -qO- $gfwlist_url | base64 -d | grep -oE "^\|\|.*" | sed "s/||/DOMAIN-SUFFIX,/" | sed 's/$/&,PROXY/')
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
FINAL,DIRECT

[Host]
localhost = 127.0.0.1
[URL Rewrite]
^http://(www.)?g.cn https://www.google.com 302
^http://(www.)?google.cn https://www.google.com 302
EOF

cat $TMPFILE
}

# 生成黑名单+屏蔽广告配置文件
function gfwlistplusconf(){
    gfwlist_url="https://raw.githubusercontent.com/v2fly/domain-list-community/release/gfwlist.txt"
    cat <<EOF >$TMPFILE
# Shadowrocket: $(date)
[General]
bypass-system = true
skip-proxy = 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, localhost, *.local, captive.apple.com
bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32
dns-server = system
ipv6 = false

[Rule]
$(domainlist category-ads-all | sed "s/^/DOMAIN-SUFFIX,&/" | sed 's/$/&,Reject/')
$(wget -qO- $gfwlist_url | base64 -d | grep -oE "^\|\|.*" | sed "s/||/DOMAIN-SUFFIX,/" | sed 's/$/&,PROXY/')
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
FINAL,DIRECT

[Host]
localhost = 127.0.0.1
[URL Rewrite]
^http://(www.)?g.cn https://www.google.com 302
^http://(www.)?google.cn https://www.google.com 302
EOF

cat $TMPFILE
}

case $1 in
    whitelistconf)
        whitelistconf
        ;;
    whitelistplusconf)
        whitelistplusconf
        ;;
    gfwlistconf)
        gfwlistconf
        ;;
    gfwlistplusconf)
        gfwlistplusconf
        ;;
    *)
        exit 1
esac
