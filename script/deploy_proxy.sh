#!/bin/bash

source .env


forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/marketplace/Marketplace.sol:MarketplaceProxy --constructor-args 0xC491903a27bDdBDECC9F4A29A486a2da84AF3326 100 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
