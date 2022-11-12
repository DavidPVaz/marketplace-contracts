#!/bin/bash

source .env


forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/marketplace/Implementation.sol:MarketplaceV1 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify