#!/bin/bash

if [ $# -eq 0 ] ; then
    echo 'You must provide the contract name as only argument'
    exit 1
fi

source .env

CONTRACT=$1

forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/${CONTRACT}.sol:${CONTRACT} --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
