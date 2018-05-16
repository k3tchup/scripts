#!/usr/bin/env bash

# Adopted from: https://superuser.com/questions/109213/how-do-i-list-the-ssl-tls-cipher-suites-a-particular-website-offers
# OpenSSL requires the port number.
SERVER=$1
PORT=$2
DELAY=1

if [ "$#" -lt 2 ]; then
    echo "Usage: $1 host port"
    exit 1
fi

ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo Obtaining cipher list from $(openssl version).

echo Testing protocol versions supported.
TLS_VERS=("ssl2" "ssl3" "tls1" "tls1_1" "tls1_2")
for TLSVER in ${TLS_VERS[@]}
do
result=$(echo -n | openssl s_client -connect $SERVER:$PORT -$TLSVER 2>/dev/null)
if [ "$?" -eq 0 ]; then
    echo "Using $TLSVER: Success"
else
    echo "Using $TLSVER: Failure"
fi
sleep $DELAY
done

for cipher in ${ciphers[@]}
do
echo -n Testing $cipher...
result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER:$PORT 2>&1)
err=$?
if [[ "$result" =~ ":error:" ]] ; then
  error=$(echo -n $result | cut -d':' -f6)
  echo NO \($error\)
else
  if [[ ( "$err" -eq 0) && ("$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ) ]] ; then
    echo YES
  else
    echo UNKNOWN RESPONSE
    echo $result
  fi
fi
sleep $DELAY
done
