#!/bin/bash

ONE_CONF="/etc/one/oned.conf"

if ! kvm-ok 2> /dev/null > /dev/null; then
	sed -i 's|type.*= "kvm"|type = "qemu"|g' ${ONE_CONF}
fi
sed -i '/backend = "sqlite"/ s|^|#|' ${ONE_CONF}

if ! grep -q "EYWA-MySQL" ${ONE_CONF}; then
echo "
#### EYWA-MySQL ####
DB = [ backend = "mysql",
       server  = "localhost",
       port    = 3306,
       user    = "root",
       passwd  = "passw0rd",
       db_name = "opennebula" ]" >> ${ONE_CONF}
fi
