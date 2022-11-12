#!/bin/bash

source .env


forge create --rpc-url ${GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} src/marketplace/Marketplace.sol:MarketplaceProxy --constructor-args 0x10043A9c6c3bd98083f721ec08067D39F1B041b7 1 --etherscan-api-key ${ETHERSCAN_API_KEY} --verify
