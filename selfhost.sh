#!/bin/bash

USER=$1
PASS=$2

# get Session ID
CGISESSID=$(curl -s -L "https://secure.selfhost.de/cgi-bin/selfhost" | grep -m 1 "CGISESSID" | sed 's/.*CGISESSID=\(.*\)" id.*/\1/' | tr -d " \t\n\r" )

# get first page
PAGE=$(curl -k -s "https://secure.selfhost.de/cgi-bin/selfhost" --data-ascii "CGISESSID=$CGISESSID&p=account&login_user=$USER&login_pass=$PASS&I1.x=47&I1.y=7")

sleep 1
if [ -z $(echo "$PAGE" | grep "Ihre Adressdaten korrekt") ];
then
    echo "Adressdaten korrekt bzw nicht abgefragt"
    STATUS=$(echo "$PAGE" | grep "Status:" | sed 's/.*Status: \(.*\)<\/a>.*/\1/' | tr -d " \t\n\r")
else
    STATUS=$(curl -k -s "https://secure.selfhost.de/cgi-bin/selfhost" --data-ascii "CGISESSID=$CGISESSID&p=account&cat=auth&formular=16&authlog=yes")
    if [ -z $(echo "$STATUS" | grep "gespeicherte Daten") ];
    then
        echo "Adressdaten erfolgreich uebernommen"
    fi
fi

# check for not empty string
if [ -z "$STATUS" ];
then
    echo "STATUS variable empty! Is USER/PASS right?"
else     
    if [ $STATUS = 'AKTIV' ];
    then
        echo "Account is $STATUS. Nothing to do..."
    else
        echo "\nAccount is $STATUS. Try to activate...\n"
        sleep 1
        # get account page
        curl -k -s "https://secure.selfhost.de/cgi-bin/selfhost?p=account&CGISESSID=$CGISESSID" > /dev/null
        sleep 1
        # activate
        curl -k -s "https://secure.selfhost.de/cgi-bin/selfhost" --data-ascii "CGISESSID=$CGISESSID&p=account&cat=auth&formular=16&authlog=yes&send=weiter…" | grep "KundenID"  
    fi
    # close session
    sleep 1
    curl -s -k "https://secure.selfhost.de/cgi-bin/selfhost?p=logout&CGISESSID=$CGISESSID" > /dev/null
fi
