#!/bin/bash

source .env


forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/nft/Pretty.sol:Pretty --constructor-args Pretty PRT https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/ 10 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
