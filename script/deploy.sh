#!/bin/bash

if [ $# -eq 0 ] ; then
    echo 'You must provide the contract name as only argument'
    exit 1
fi

source .env

FOLDER=$1
CONTRACT=$2

forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/${FOLDER}/${CONTRACT}.sol:${CONTRACT} --constructor-args 1 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
