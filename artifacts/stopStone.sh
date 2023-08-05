export PASSWORD=`cat /etc/gemstone/secret`
stopstone -i gs64stone DataCurator $PASSWORD
# while stopstone exits with 0, stoned exits with 3
# https://kermit.gemtalksystems.com/bug?bug=50222