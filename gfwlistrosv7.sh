#!/bin/bash
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

#copied & modified from atrandys trojan scripts
#copy from Zhihong ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
fi

if [ ${systemPackage} == "yum" ]; then
    ${sudoCmd} ${systemPackage} install wget -y -q
else
    ${sudoCmd} ${systemPackage} install wget -y -qq
fi

if [ ${release} == "centos" ]; then
    nginx_root="/usr/share/nginx/html"
else
    nginx_root="/var/www/html"
fi

echo "domain downloading !!"

#download gfwlist.txt,rename base64.txt
wget -O base64.txt https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt > /dev/null 2>&1

#wait for 3s
sleep 3

echo "domain downloads done!!"

# 设置环境变量
echo "Environment variable"
gfwlist_domain_filename="./Result/gfwlist7_domain.rsc"
gfwlist_source_domain_filename="./Result/gfwlist7_domain_source.rsc"

chmod +x gfwlistdnsmasq.sh && sh ./gfwlistdnsmasq.sh -l -o ${gfwlist_domain_filename}

cp ${gfwlist_domain_filename} ${gfwlist_source_domain_filename}


# 增加额外需要加入gfwlist的域名
echo "libreswan.org" >> ${gfwlist_domain_filename}
echo "i.ytimg.com" >> ${gfwlist_domain_filename}
echo "download.mikrotik.com" >> ${gfwlist_domain_filename}



# 开始进行Mikrotik翻译
echo "Mikrotik Domain Translate !! "
# RouterOS v7 gfwlist scripts
sed -i 's/^/:do { add comment=Gfwlist type=FWD forward-to=8.8.8.8 match-subdomain=yes name=&/g' ${gfwlist_domain_filename}
sed -i 's/$/&\ } on-error={}/g' ${gfwlist_domain_filename}

# 在文件第4行前插入新行"/ip dns static remove [ find comment=Gfwlist ]"
sed -i '1 i/ip dns static/remove [ find comment=Gfwlist ]' ${gfwlist_domain_filename}

# 在文件第5行前插入新行"/ip dns static"
sed -i '2 i/ip dns static' ${gfwlist_domain_filename}

# 在文件的最后一行插入新行"/ip dns cache flush"
sed -i '$ a/ip dns cache flush' ${gfwlist_domain_filename}

# 在文件的最后一行的前一行插入新行“:delay 3s;”
sed -i '$ i:delay 3s;' ${gfwlist_domain_filename}

# 翻译完成
echo "Translation completed !!"
