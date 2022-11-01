// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/marketplace/Marketplace.sol';
import '../src/nft/Pretty.sol';

contract MarketplaceTest is Test {
    event Listed(address indexed collection, address indexed seller, uint256 nftId);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    address public constant MARKETPLACE_CONTRACT_OWNER = address(1000);
    address public constant CREATOR = address(999);
    address public constant PRETTY_MINTER = address(998);
    uint8 public fee = 1;
    Marketplace public marketplace;
    Pretty public pretty;

    function setUp() public {
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace = new Marketplace(fee);

        vm.prank(CREATOR);
        pretty = new Pretty('Pretty', 'PRT', 'https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/', 2);

        vm.deal(PRETTY_MINTER, 0.5 ether);
        vm.startPrank(PRETTY_MINTER);
        pretty.mint{value: 0.0001 ether}();
        pretty.mint{value: 0.0001 ether}();
        vm.stopPrank();
    }

    function testShouldAllowToSetFee() public {
        // setup
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        uint8 newFee = 2;

        // exercise
        marketplace.setFee(newFee);

        // verify
        assertEq(marketplace.percentageFee(), newFee);
    }

    function testShouldNotAllowToSetFee() public {
        // setup
        vm.prank(address(1));
        uint8 newFee = 2;

        // vm verify
        vm.expectRevert(Marketplace.Unauthorized.selector);

        // exercise
        marketplace.setFee(newFee);
    }

    function testShouldAllowToWithdraw() public {
        // setup
        vm.deal(address(marketplace), 1 ether);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // exercise
        marketplace.withdraw();

        // verify
        assertEq(address(marketplace).balance, 0 ether);
        assertEq(MARKETPLACE_CONTRACT_OWNER.balance, 1 ether);
    }

    function testShouldNotAllowToWithdraw() public {
        // setup
        vm.deal(address(marketplace), 1 ether);
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(Marketplace.Unauthorized.selector);

        // exercise
        marketplace.withdraw();

        // verify
        assertEq(address(marketplace).balance, 1 ether);
    }

    function testShouldAllowToListACollection() public {
        // setup
        address collection = address(pretty);
        vm.prank(CREATOR);

        // exercise
        marketplace.listInMarketplace(collection);

        // verify
        Marketplace.Collection[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 1);
        assertTrue(collections[0].listed);
        assertEq(collections[0].creator, CREATOR);
    }

    function testShouldNotAllowToListACollectionIfNotCreator() public {
        // setup
        address collection = address(pretty);
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(Marketplace.Unauthorized.selector);

        // exercise
        marketplace.listInMarketplace(collection);

        // verify
        Marketplace.Collection[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 0);
    }

    function testShouldNotAllowToListACollectionIfAlreadyListed() public {
        // setup
        address collection = address(pretty);
        vm.startPrank(CREATOR);
        marketplace.listInMarketplace(collection);

        // vm verify
        vm.expectRevert(Marketplace.AlreadyListed.selector);

        // exercise
        marketplace.listInMarketplace(collection);

        // verify
        Marketplace.Collection[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 1);

        // cleanup
        vm.stopPrank();
    }
}
