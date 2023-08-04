topaz -lq << EOF
set u DataCurator p OLD_PASSWORD gems gs64stone
login
run
(AllUsers userWithId: 'DataCurator') password: 'NEW_PASSWORD'.
(AllUsers userWithId: 'SystemUser') password: 'NEW_PASSWORD'.
System commit.
%
logout
exit
EOF
