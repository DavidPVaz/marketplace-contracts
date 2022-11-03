#!/bin/bash

if [ $# -eq 0 ] ; then
    echo 'You must provide the source folder and contract name as arguments'
    exit 1
fi

source .env

FOLDER=$1
CONTRACT=$2

forge create --rpc-url ${DEV_RPC_URL} --private-key ${DEV_PRIVATE_KEY} src/${FOLDER}/${CONTRACT}.sol:${CONTRACT} --constructor-args Pretty PRT https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/ 10
