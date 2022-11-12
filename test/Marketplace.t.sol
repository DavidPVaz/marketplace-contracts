// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/marketplace/Implementation.sol';
import '../src/marketplace/Marketplace.sol';
import '../src/nft/Pretty.sol';

contract MarketplaceTest is Test {
    address public constant ADMIN = address(1000);
    MarketplaceV1 public implementation;
    MarketplaceProxy public proxy;
    Pretty public collection;

    function setUp() public {
        implementation = new MarketplaceV1();

        vm.prank(ADMIN);
        collection = new Pretty(
            'Pretty',
            'PRT',
            'https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/',
            3
        );
    }

    function testShouldSuccessfullyCreateProxy() public {
        // setup
        uint8 initialFee = 5;
        vm.startPrank(ADMIN);

        // exercise
        proxy = new MarketplaceProxy(address(implementation), initialFee);

        // verify
        assertEq(proxy.admin(), ADMIN);
        assertEq(proxy.implementation(), address(implementation));

        // cleanup
        vm.stopPrank();
    }

    function testShouldSuccessfullyDelegateCallIfAdmin() public {
        // setup
        uint8 initialFee = 5;
        uint8 newFee = 10;
        vm.startPrank(ADMIN);
        proxy = new MarketplaceProxy(address(implementation), initialFee);

        // exercise && verify
        (bool success, ) = address(proxy).call(abi.encodeWithSignature('setFee(uint8)', newFee));
        assertTrue(success);

        (, bytes memory updatedFee) = address(proxy).call(abi.encodeWithSignature('percentageFee()'));
        assertEq(abi.decode(updatedFee, (uint8)), newFee);

        // cleanup
        vm.stopPrank();
    }

    function testShouldSuccessfullyListACollectionInMarketplace() public {
        // setup
        uint8 initialFee = 5;
        vm.startPrank(ADMIN);
        proxy = new MarketplaceProxy(address(implementation), initialFee);

        // exercise && verify
        (bool success, ) = address(proxy).call(
            abi.encodeWithSignature('listInMarketplace(address,address,uint8)', address(collection), ADMIN, 5)
        );
        assertTrue(success);

        (bool ok, bytes memory collections) = address(proxy).call(abi.encodeWithSignature('getCollections()'));
        assertTrue(ok);
        assertEq(abi.decode(collections, (address[]))[0], address(collection));

        // cleanup
        vm.stopPrank();
    }

    function testShouldSuccessfullyDelegateCallIfNotAdmin() public {
        // setup
        uint8 initialFee = 5;
        vm.prank(ADMIN);
        proxy = new MarketplaceProxy(address(implementation), initialFee);

        // exercise && verify
        (bool successOwnerCall, bytes memory owner) = address(proxy).call(abi.encodeWithSignature('owner()'));
        assertTrue(successOwnerCall);
        assertEq(abi.decode(owner, (address)), ADMIN);

        (bool successPercentageCall, bytes memory initialPercentageFee) = address(proxy).call(
            abi.encodeWithSignature('percentageFee()')
        );
        assertTrue(successPercentageCall);
        assertEq(abi.decode(initialPercentageFee, (uint8)), initialFee);

        (bool ok, bytes memory collections) = address(proxy).call(abi.encodeWithSignature('getCollections()'));
        assertTrue(ok);
        assertEq(abi.decode(collections, (address[])).length, 0);

        (bool failed, ) = address(proxy).call(abi.encodeWithSignature('doesNotExist()'));
        assertFalse(failed);

        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        (bool successfulCall, bytes memory result) = address(proxy).call(abi.encodeWithSignature('setFee(uint8)', 20));
        assertTrue(successfulCall);
        assertFalse(abi.decode(result, (bool)));

        vm.expectRevert();

        proxy.implementation();
    }

    function testShouldSuccessfullyDelegateCallAndFailIfNotAdminOrOwner() public {
        // setup
        uint8 initialFee = 5;
        vm.prank(ADMIN);
        proxy = new MarketplaceProxy(address(implementation), initialFee);

        // exercise && verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        (bool successfulCall, bytes memory result) = address(proxy).call(abi.encodeWithSignature('setFee(uint8)', 20));
        assertTrue(successfulCall);
        assertFalse(abi.decode(result, (bool)));

        vm.expectRevert();

        proxy.implementation();
    }
}
