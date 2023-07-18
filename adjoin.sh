#!/bin/bash

# Asagidaki değişkenleri kendi değerlerinizle değiştirin
AD_DOMAIN="hurriyetim.com.tr"
AD_ADMIN_USERNAME="serviceadmin"
AD_ADMIN_PASSWORD="xx"
AD_OU="OU=Servers,DC=hurriyetim,DC=com,DC=tr"
LINUX_HOSTNAME="xxxx"
LINUX_IP_ADDRESS="10.20.xx.x"

# Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings. HATAYI GIDERMEK ICIN
sudo rm /var/lib/ubuntu-release-upgrader/release-upgrade-available
sudo /usr/lib/ubuntu-release-upgrader/release-upgrade-motd


#ubuntu 22.04 icin bu paketler kurulur
sudo apt-get update; sudo apt upgrade -y
sudo apt-get install -y realmd sssd samba-common krb5-user
#echo <ipaddress> <hostname> >> /etc/hosts
#ubuntu 18.04 icin bu paketler kurulur
#sudo apt-get update
#sudo apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

# belirlenen domaine sunucu dahil edilir 
sudo realm join --verbose --user=$AD_ADMIN_USERNAME $AD_DOMAIN \
    --computer-ou="$AD_OU" \
    --os-name="Linux" \
    --os-version="7" \
    --automatic-id-mapping=no

# SSSD konfigure edilir
sudo sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
sudo sed -i 's/fallback_homedir = \/home\/%u@%d/fallback_homedir = \/home\/%u/g' /etc/sssd/sssd.conf
sudo sed -i 's/access_provider = ad/access_provider = ad/g' /etc/sssd/sssd.conf
sudo systemctl restart sssd
sudo systemctl enable sssd

# domain kullanicisi için ssh izni verilir
sudo sed -i 's/#AuthorizedKeysCommand none/AuthorizedKeysCommand \/usr\/bin\/sss_ssh_authorizedkeys/g' /etc/ssh/sshd_config
sudo sed -i 's/#AuthorizedKeysCommandUser nobody/AuthorizedKeysCommandUser nobody/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo pam-auth-update --enable mkhomedir
