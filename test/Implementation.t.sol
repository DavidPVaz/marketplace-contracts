// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/marketplace/Implementation.sol';
import '../src/nft/Pretty.sol';

contract MarketplaceV1Test is Test {
    event Listed(address indexed collection, address indexed seller, uint256 nftId, uint256 price);
    event UpdateListing(address indexed collection, address indexed seller, uint256 nftId, uint256 newPrice);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    address public constant MARKETPLACE_CONTRACT_OWNER = address(1000);
    address public constant CREATOR = address(999);
    address public constant PRETTY_MINTER = address(998);
    address public constant BUYER = address(997);
    uint16 public fee = 100; // 1% in basis points
    MarketplaceV1 public marketplace;
    Pretty public pretty;

    function setUp() public {
        marketplace = new MarketplaceV1();
        marketplace.initialize(MARKETPLACE_CONTRACT_OWNER, fee);

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
        uint16 newFee = 200;

        // exercise
        marketplace.setFee(newFee);

        // verify
        assertEq(marketplace.percentageFee(), newFee);
    }

    function testShouldNotAllowToSetFee() public {
        // setup
        vm.prank(address(1));
        uint16 newFee = 200;

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

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
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.withdraw();

        // verify
        assertEq(address(marketplace).balance, 1 ether);
    }

    function testShouldAllowToTransferOwnership() public {
        // setup
        address newOwner = address(5);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // exercise
        marketplace.transferOwnership(newOwner);

        // verify
        assertEq(marketplace.owner(), newOwner);
    }

    function testShouldNotAllowToTransferOwnershipIfNotOwner() public {
        // setup
        address newOwner = address(5);
        vm.prank(address(5));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.transferOwnership(newOwner);

        // verify
        assertEq(marketplace.owner(), MARKETPLACE_CONTRACT_OWNER);
    }

    function testShouldNotAllowToTransferOwnershipToZeroAddress() public {
        // setup
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // vm verify
        vm.expectRevert(MarketplaceV1.IsZeroAddress.selector);

        // exercise
        marketplace.transferOwnership(address(0));

        // verify
        assertEq(marketplace.owner(), MARKETPLACE_CONTRACT_OWNER);
    }

    function testShouldAllowToListACollection() public {
        // setup
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // exercise
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // verify
        address[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 1);
        assertEq(collections[0], collection);
    }

    function testShouldNotAllowToListACollectionIfCreatorIsWrong() public {
        // setup
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.listInMarketplace(collection, address(2), 200);

        // verify
        address[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 0);
    }

    function testShouldNotAllowToListACollectionWithExcessRoyalties() public {
        // setup
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // vm verify
        vm.expectRevert(MarketplaceV1.ExceededAllowedRoyalties.selector);

        // exercise
        marketplace.listInMarketplace(collection, CREATOR, 9901);

        // verify
        address[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 0);
    }

    function testShouldNotAllowToListACollectionIfNotMarketplaceOwner() public {
        // setup
        address collection = address(pretty);
        vm.prank(address(3));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // verify
        address[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 0);
    }

    function testShouldNotAllowToListACollectionIfAlreadyListed() public {
        // setup
        address collection = address(pretty);
        vm.startPrank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // vm verify
        vm.expectRevert(MarketplaceV1.AlreadyListed.selector);

        // exercise
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // verify
        address[] memory collections = marketplace.getCollections();
        assertEq(collections.length, 1);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowToUpdateRoyalties() public {
        // setup
        address collection = address(pretty);
        vm.startPrank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // exercise
        marketplace.updateCollectionRoyalties(collection, 9900);

        // verify
        assertEq(marketplace.getCollectionRoyalties(collection), 9900);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotGetRoyaltiesOfInvalidCollection() public {
        // setup
        address collection = address(pretty);

        // vm verify
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.getCollectionRoyalties(collection);
    }

    function testShouldNotAllowToUpdateRoyaltiesIfInvalidCollection() public {
        // setup
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);

        // vm verify
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.updateCollectionRoyalties(collection, 500);
    }

    function testShouldNotAllowToUpdateRoyaltiesIfNotMarketplaceOwner() public {
        // setup
        address collection = address(pretty);
        vm.prank(address(3));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.updateCollectionRoyalties(collection, 500);
    }

    function testShouldNotAllowToUpdateRoyaltiesIfExcessRoyalties() public {
        // setup
        address collection = address(pretty);
        vm.startPrank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);

        // vm verify
        vm.expectRevert(MarketplaceV1.ExceededAllowedRoyalties.selector);

        // exercise
        marketplace.updateCollectionRoyalties(collection, 9901);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowToListNft() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
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
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.list(collection, nftId, price);
    }

    function testShouldNotAllowToListNftIfNotOwner() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);

        vm.prank(address(1));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.list(collection, nftId, price);
    }

    function testShouldNotAllowToListNftIfAlreadyListed() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.startPrank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        marketplace.list(collection, nftId, price);

        // vm verify
        vm.expectRevert(MarketplaceV1.AlreadyListed.selector);

        // exercise
        marketplace.list(collection, nftId, price);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowToUpdateListing() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        uint256 newPrice = 2 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.startPrank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        marketplace.list(collection, nftId, price);

        // vm verify
        vm.expectEmit(true, true, false, true);
        emit UpdateListing(collection, PRETTY_MINTER, nftId, newPrice);

        // exercise
        marketplace.updateListing(collection, nftId, newPrice);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowToUpdateListingOfInvalidCollection() public {
        // setup
        uint256 nftId = 1;
        uint256 newPrice = 2 ether;
        address collection = address(pretty);

        // vm verify
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.updateListing(collection, nftId, newPrice);
    }

    function testShouldNotAllowToUpdateListingIfNotOwner() public {
        // setup
        uint256 nftId = 1;
        uint256 newPrice = 2 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(address(2));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.updateListing(collection, nftId, newPrice);
    }

    function testShouldNotAllowToUpdateListingIfNotListed() public {
        // setup
        uint256 nftId = 1;
        uint256 newPrice = 2 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectRevert(MarketplaceV1.NotListed.selector);

        // exercise
        marketplace.updateListing(collection, nftId, newPrice);
    }

    function testShouldAllowToCancelListing() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
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
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldNotAllowToCancelListingIfNotOwner() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldNotAllowToCancelListingIfNftIsNotListed() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(PRETTY_MINTER);

        // vm verify
        vm.expectRevert(MarketplaceV1.NotListed.selector);

        // exercise
        marketplace.cancelListing(collection, nftId);
    }

    function testShouldAllowToBuyNft() public {
        // setup
        uint256 expectedMarketplaceBalance = 0.01 ether;
        uint256 expectedCreatorBalance = 0.02 ether;
        uint256 expectedSellerBalance = 0.97 ether;
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.deal(PRETTY_MINTER, 0 ether);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
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
        assertEq(CREATOR.balance, expectedCreatorBalance);
        assertEq(BUYER.balance, 0);
    }

    function testShouldAllowToBuyNftWithMaxRoyalties() public {
        // setup
        uint256 expectedMarketplaceBalance = 0.01 ether;
        uint256 expectedCreatorBalance = 0.99 ether;
        uint256 expectedSellerBalance = 0 ether;
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.deal(PRETTY_MINTER, 0 ether);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 9900);
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
        assertEq(CREATOR.balance, expectedCreatorBalance);
        assertEq(BUYER.balance, 0);
    }

    function testShouldNotAllowToBuyInvalidCollection() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(MarketplaceV1.InvalidCollection.selector);

        // exercise
        marketplace.buy(collection, nftId);
    }

    function testShouldNotAllowToBuyIfNftIsNotListed() public {
        // setup
        uint256 nftId = 1;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(MarketplaceV1.NotListed.selector);

        // exercise
        marketplace.buy(collection, nftId);
    }

    function testShouldNotAllowToBuyIfBuyerIsSeller() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.startPrank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        marketplace.list(collection, nftId, price);

        // vm verify
        vm.expectRevert(MarketplaceV1.Unauthorized.selector);

        // exercise
        marketplace.buy(collection, nftId);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowToBuyIfNotCorrectPayment() public {
        // setup
        uint256 nftId = 1;
        uint256 price = 1 ether;
        address collection = address(pretty);
        vm.prank(MARKETPLACE_CONTRACT_OWNER);
        marketplace.listInMarketplace(collection, CREATOR, 200);
        vm.prank(PRETTY_MINTER);
        pretty.approve(address(marketplace), nftId); // setting approve first
        vm.prank(PRETTY_MINTER);
        marketplace.list(collection, nftId, price);
        vm.deal(BUYER, 0.5 ether);
        vm.prank(BUYER);

        // vm verify
        vm.expectRevert(MarketplaceV1.InvalidPayment.selector);

        // exercise
        marketplace.buy{value: 0.5 ether}(collection, nftId);
    }
}
