topaz -lq << EOF
set user SystemUser pass swordfish gems gs64stone
login
send StringConfiguration enableUnicodeComparisonMode
commit
logout
exit
EOF
