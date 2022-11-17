# **NFT Marketplace**

## **Project Description**:

- This project consists of Solidity Smart Contracts and also a DAPP, but only the smart contracts are shared in this repo. It was developed as a capstone project for the Artemis Academy Web3 bootcamp.
- Although there a lot more features that could be added, this is a MVP of the idealized product, were the main concern was to provide a fully functional MVP.
- The first step was to implement an ERC721 contract. Metadata was also generated an uploaded to IPFS. There was no point in having a marketplace if I don't have a NFT collection to list there. 
Once completed, I began the marketplace contract development with a Proxy pattern. It goes without saying, all contracts are tested.
- The contracts are deployed to Goerli testnet and the addresses are as follow:
  - ERC721: [0x3979faA7e839a9370a139a9F00E60B87FCee16D8](https://goerli.etherscan.io/address/0x3979faA7e839a9370a139a9F00E60B87FCee16D8)
  - Proxy: [0x3736C101343d2605d5505CCAc87CED557d9a2EAc](https://goerli.etherscan.io/address/0x3736C101343d2605d5505CCAc87CED557d9a2EAc)
  - Implementation: [0xC491903a27bDdBDECC9F4A29A486a2da84AF3326](https://goerli.etherscan.io/address/0xC491903a27bDdBDECC9F4A29A486a2da84AF3326)
- Feel free to play around with the dapp. Only metamask is supported.
  - https://artemis-marketplace.netlify.app/

## **Tools used**:

#### **Smart Contracts**:

- Foundry
- Solidity 0.8.17

#### **Dapp**:

 - Javascript
 - React
 - ethers
 - styled-components
 - react-notifications-component
 
 #### **Others**:

 - Pinata
 - The Graph
 - Metamask

## **Generic architecture overview**:

![Imgur](https://i.imgur.com/9rk08ie.png)
