// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/marketplace/Marketplace.sol';
import '../src/nft/Pretty.sol';

contract MarketplaceTest is Test {
    event Listed(address indexed collection, address indexed seller, uint256 nftId, uint256 price);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    address public constant MARKETPLACE_CONTRACT_OWNER = address(1000);
    address public constant CREATOR = address(999);
    address public constant PRETTY_MINTER = address(998);
    address public constant BUYER = address(997);
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
        assertEq(collections[0].collection, collection);
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

    function testShouldAllowToListNft() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectEmit(true, true, false, true);
        emit Listed(collection, PRETTY_MINTER, nftId, price);

        // exercise
        marketplace.list(collection, nftId, price);

        // verify
        assertEq(pretty.ownerOf(nftId), address(marketplace));
    }

    function testShouldNotAllowToListInvalidCollection() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectRevert(Marketplace.InvalidCollection.selector);

        // exercise
        marketplace.list(collection, nftId, price);
    }

    function testShouldNotAllowToListNftIfNotOwner() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(Marketplace.Unauthorized.selector);

        // exercise
        marketplace.list(collection, nftId, price);
    }

    function testShouldNotAllowToListNftIfAlreadyListed() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.startPrank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        marketplace.list(collection, nftId, price);

        // vm verify
        vm.expectRevert(Marketplace.AlreadyListed.selector);

        // exercise
        marketplace.list(collection, nftId, price);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowToCancelListing() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.startPrank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        marketplace.list(collection, nftId, price);

        // vm verify
        vm.expectEmit(true, true, false, true);
        emit CancelListing(collection, PRETTY_MINTER, nftId);

        // exercise
        marketplace.cancelListing(collection, nftId);

        // verify
        assertEq(pretty.ownerOf(nftId), PRETTY_MINTER);
    }

    function testShouldNotAllowToCancelListingOfInvalidCollection() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectRevert(Marketplace.InvalidCollection.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldNotAllowToCancelListingIfNotOwner() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(Marketplace.Unauthorized.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldNotAllowToCancelListingIfNftIsNotListed() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectRevert(Marketplace.NotListed.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldAllowToBuyNft() public {
        // setup
        uint256 expectedMarketplaceBalance = 0.01 ether;
        uint256 expectedSellerBalance = 0.99 ether;
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.deal(PRETTY_MINTER, 0 ether);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        vm.prank(PRETTY_MINTER);
        marketplace.list(collection, nftId, price);
        vm.deal(BUYER, price);
        vm.prank(BUYER);

        // vm verify
        vm.expectEmit(true, true, false, true);
        emit Bought(collection, BUYER, nftId, price);

        // exercise
        marketplace.buy{value: price}(collection, nftId);

        // verify
        assertEq(pretty.ownerOf(nftId), BUYER);
        assertEq(address(marketplace).balance, expectedMarketplaceBalance);
        assertEq(PRETTY_MINTER.balance, expectedSellerBalance);
        assertEq(BUYER.balance, 0);
    }

    function testShouldNotAllowToBuyInvalidCollection() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(Marketplace.InvalidCollection.selector);

        // exercise
        marketplace.buy(collection, nftId);
    }

    function testShouldNotAllowToBuyIfNftIsNotListed() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(Marketplace.NotListed.selector);

        // exercise
        marketplace.buy(collection, nftId);
    }

    function testShouldNotAllowToBuyIfNotCorrectPayment() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(CREATOR);
        marketplace.listInMarketplace(collection);
        vm.prank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        vm.prank(PRETTY_MINTER);
        marketplace.list(collection, nftId, price);
        vm.deal(BUYER, 0.5 ether);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(Marketplace.InvalidPayment.selector);

        // exercise
        marketplace.buy{value: 0.5 ether}(collection, nftId);
    }
}
