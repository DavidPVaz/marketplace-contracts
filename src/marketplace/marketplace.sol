// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract MarketplaceProxy is TransparentUpgradeableProxy {
    constructor(address implementation, uint8 initialMarketplaceFee)
        TransparentUpgradeableProxy(implementation, msg.sender, _getSignature(msg.sender, initialMarketplaceFee))
    {}

    function _getSignature(address owner, uint8 fee) private pure returns (bytes memory) {
        return abi.encodeWithSignature('initialize(address,uint8)', owner, fee);
    }

    /**
     * @dev Overriding to make sure that admin calls also delegate to implementation.
     */
    function _beforeFallback() internal override {}
}
