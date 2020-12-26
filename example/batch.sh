#!/bin/bash

echo "word;address;key;url;balance"
export BLOCKCYPHER_TOKEN="" # your token from https://accounts.blockcypher.com/

while read p; do
  word=$p
  data=$(./../bw.sh -j -b -p $word)
  url=`echo $data | jq ".blockchain_URL"`
  address=`echo $data | jq ".address_uncompressed"`
  key=`echo $data | jq ".private_key_base58"`
  balance=`echo $data | jq ".balance_BTC_sat"`
  received=`echo $data | jq ".received_BTC"`

  echo "${word};${address};${key};${url};${balance};${received}"

  sleep 1
done <data.txt

