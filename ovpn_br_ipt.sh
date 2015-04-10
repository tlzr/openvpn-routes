#!/bin/sh

SERVER_CONF='/etc/openvpn/server.conf'
OPENVPN_SUBNET='10.100.0.0/24'
IPT='/sbin/iptables'

for i in `brctl show | cut -f1 | egrep -v '^$'`
do
    BRNAME=$i
    INETLINE=`ifconfig $BRNAME | grep "inet addr"`

    if ! [ -z "$INETLINE" ]
    then
        #echo $BRNAME
    	BRIP=`echo $INETLINE | grep -o -P '(?<=inet addr:)[0-9]+\.[0-9]+\.[0-9]+'`
   		BRMASK=`echo $INETLINE | grep -o -P '(?<=Mask:)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'`
        PUSH_LINE="push \"route ${BRIP}.0 ${BRMASK}\""
        LINES=`grep "$PUSH_LINE" "$SERVER_CONF" | wc -l`
        if ! [ -z $LINES ] && [ $LINES -lt 1 ]
        then
            echo $PUSH_LINE >> $SERVER_CONF
            if ! [ `$IPT -t nat -C POSTROUTING -s "$OPENVPN_SUBNET" -o "$BRNAME" -j MASQUERADE` ]
            then
                $IPT -t nat -A POSTROUTING -s "$OPENVPN_SUBNET" -o "$BRNAME" -j MASQUERADE
            fi
        fi
    fi
done

