cp /var/lib/gemstone/bin/changePassword.sh /pitcairn1/users/jfoster/changePassword.sh
PASSWORD=`cat /etc/gemstone/secret`
sed -i "s/OLD_PASSWORD/swordfish/g" /pitcairn1/users/jfoster/changePassword.sh
sed -i "s/NEW_PASSWORD/$PASSWORD/g" /pitcairn1/users/jfoster/changePassword.sh
/pitcairn1/users/jfoster/changePassword.sh
rm /pitcairn1/users/jfoster/changePassword.sh
