cp /usr/lib/gemstone/bin/changePassword.sh /tmp/changePassword.sh
PASSWORD=`cat /etc/gemstone/password`
sed -i "s/OLD_PASSWORD/$PASSWORD/g" /tmp/changePassword.sh
sed -i "s/NEW_PASSWORD/swordfish/g" /tmp/changePassword.sh
/tmp/changePassword.sh
rm /tmp/changePassword.sh
