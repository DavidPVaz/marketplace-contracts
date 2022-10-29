// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/ERC721.sol';
import '../src/IERC721TokenReceiver.sol';

contract TokenReceiver is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract ERC721Test is Test {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    address public constant NFT_CONTRACT_OWNER = address(1000);
    bytes4 public constant IERC721_ID = 0x80ac58cd;
    bytes4 public constant IERC721_METADATA_ID = 0x5b5e139f;
    bytes4 public constant IERC721_TOKEN_RECEIVER_ID = 0x150b7a02;

    TokenReceiver tokenReceiver = new TokenReceiver();

    uint256 public tokenId;
    ERC721 public nftContract;

    function setUp() public {
        tokenId = 0;
        vm.prank(NFT_CONTRACT_OWNER);
        nftContract = new ERC721('Artemisians', 'ART');
    }

    function testShouldGetSuportedInterfaces() public {
        // exercise && verify
        assertTrue(nftContract.supportsInterface(IERC721_ID));
        assertTrue(nftContract.supportsInterface(IERC721_METADATA_ID));
        assertFalse(nftContract.supportsInterface(IERC721_TOKEN_RECEIVER_ID));
    }

    function testShouldGetName() public {
        // exercise && verify
        assertEq(nftContract.name(), 'Artemisians');
    }

    function testShouldGetSymbol() public {
        // exercise && verify
        assertEq(nftContract.symbol(), 'ART');
    }

    function testShouldAllowMint() public {
        // setup
        address minter = address(2);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), minter, ++tokenId);

        // exercise
        nftContract.mint(minter, tokenId);

        // verify
        assertEq(nftContract.balanceOf(minter), 1);
        assertEq(nftContract.ownerOf(tokenId), minter);
    }

    function testNotShouldAllowMintToZeroAddress() public {
        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        nftContract.mint(address(0), ++tokenId);
    }

    function testShouldGetTokenURI() public {
        // setup
        nftContract.mint(address(2), ++tokenId);

        // exercise && verify
        assertEq(nftContract.tokenURI(tokenId), '<some_uri>');
    }

    function testShouldNotGetTokenURIOfInvalidToken() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        nftContract.tokenURI(tokenId);
    }

    function testShouldGetTheBalanceOfAnOwner() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // exercise && verify
        assertEq(nftContract.balanceOf(minter), 1);
        assertEq(nftContract.balanceOf(address(3)), 0);
    }

    function testShouldNotGetTheBalanceOfZeroAddress() public {
        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        nftContract.balanceOf(address(0));
    }

    function testShouldGetOwnerOfToken() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // exercise && verify
        assertEq(nftContract.ownerOf(tokenId), minter);
    }

    function testShouldNotGetOwnerOfInvalidToken() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        nftContract.ownerOf(tokenId);
    }

    function testShouldAllowBurn() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, address(0), tokenId);

        // 1º exercise
        nftContract.burn(tokenId);

        // verify
        assertEq(nftContract.balanceOf(minter), 0);

        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // 2º exercise
        nftContract.ownerOf(tokenId);
    }

    function testShouldNotAllowBurnOfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        nftContract.burn(tokenId);
    }

    function testShouldNotAllowBurnIfNotOwner() public {
        // setup
        nftContract.mint(address(2), ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.burn(tokenId);
    }

    function testShouldGetApproved() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // exercise && verify
        assertEq(nftContract.getApproved(tokenId), address(0));
    }

    function testShouldNotGetApprovedForInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise && verify
        nftContract.getApproved(tokenId);
    }

    function testShouldAllowOwnerToApprove() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, address(this), tokenId);

        // exercise
        nftContract.approve(address(this), tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(this));
    }

    function testShouldAllowOwnerToRevokeApprove() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, address(0), tokenId);

        // exercise
        nftContract.approve(address(0), tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
    }

    function testShouldAllowOperatorToApprove() public {
        // setup
        address operator = address(10);
        address minter = address(2);
        address approved = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        nftContract.setApprovalForAll(operator, true);

        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, approved, tokenId);

        // exercise
        nftContract.approve(approved, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), approved);
    }

    function testShouldNotAllowToApproveIfNotAuthorized() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.approve(address(this), tokenId);
    }

    function testShouldNotAllowToApproveIfTargetIsMsgSender() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectRevert(ERC721.SelfTarget.selector);

        // exercise
        nftContract.approve(minter, tokenId);
    }

    function testShouldAllowSetupApprovalForAll() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(minter, operator, true);

        // exercise
        nftContract.setApprovalForAll(operator, true);

        // verify
        assertTrue(nftContract.isApprovedForAll(minter, operator));
    }

    function testShouldAllowToRevokeApprovalForAll() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(minter, operator, false);

        // exercise
        nftContract.setApprovalForAll(operator, false);

        // verify
        assertFalse(nftContract.isApprovedForAll(minter, operator));
    }

    function testShouldNotAllowSetupApprovalForAllIfNotAnOwner() public {
        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.setApprovalForAll(address(this), true);
    }

    function testShouldNotAllowToSetupApprovalForAllIfSelfTarget() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectRevert(ERC721.SelfTarget.selector);

        // exercise
        nftContract.setApprovalForAll(minter, true);
    }

    function testShouldNotAllowToSetupApprovalForAllIfZeroAddress() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        nftContract.setApprovalForAll(address(0), true);
    }

    function testShouldGetApprovedForALl() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);
        nftContract.setApprovalForAll(operator, true);

        // exercise && verify
        assertTrue(nftContract.isApprovedForAll(minter, operator));
        assertFalse(nftContract.isApprovedForAll(minter, address(4)));
        assertFalse(nftContract.isApprovedForAll(operator, minter));
        assertFalse(nftContract.isApprovedForAll(address(0), address(7)));
    }

    function testShouldAllowTransferFromIfOnwer() public {
        // setup
        address minter = address(2);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.transferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldAllowTransferFromIfApproved() public {
        // setup
        address minter = address(2);
        address approved = address(3);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);
        nftContract.approve(approved, tokenId);
        vm.prank(approved);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.transferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldAllowTransferFromIfAllowedOperator() public {
        // setup
        address minter = address(2);
        address operator = address(3);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);
        nftContract.setApprovalForAll(operator, true);
        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.transferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldNotAllowTransferFromIfNotAuthorized() public {
        // setup
        address minter = address(2);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.transferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.balanceOf(minter), 1);
        assertEq(nftContract.ownerOf(tokenId), minter);
    }

    function testShouldNotAllowTransferFromIfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        nftContract.transferFrom(address(1), address(2), tokenId);
    }

    function testShouldNotAllowTransferFromIfToZeroAddress() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        nftContract.transferFrom(minter, address(0), tokenId);
    }

    function testShouldNotAllowTransferFromIfFromIsNotTheOwner() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.transferFrom(address(1), address(10), tokenId);
    }

    function testShouldAllowSafeTransferFromIfOnwer() public {
        // setup
        address minter = address(2);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.safeTransferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldAllowSafeTransferFromIfApproved() public {
        // setup
        address minter = address(2);
        address approved = address(3);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);
        nftContract.approve(approved, tokenId);
        vm.prank(approved);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.safeTransferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldAllowSafeTransferFromIfAllowedOperator() public {
        // setup
        address minter = address(2);
        address operator = address(3);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);
        nftContract.setApprovalForAll(operator, true);
        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.safeTransferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldAllowSafeTransferFromToATokenReceiverContract() public {
        // setup
        address minter = address(2);
        address to = address(tokenReceiver);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, tokenId);

        // exercise
        nftContract.safeTransferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.getApproved(tokenId), address(0));
        assertEq(nftContract.balanceOf(minter), 0);
        assertEq(nftContract.balanceOf(to), 1);
        assertEq(nftContract.ownerOf(tokenId), to);
    }

    function testShouldNotAllowSafeTransferFromToContractThatDoesNotImplementTokenReceiver() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);
        vm.prank(minter);

        // vm verify
        vm.expectRevert(ERC721.NonERC721TokenReceiver.selector);

        // exercise
        nftContract.safeTransferFrom(minter, address(this), tokenId);

        // verify
        assertEq(nftContract.balanceOf(minter), 1);
        assertEq(nftContract.ownerOf(tokenId), minter);
    }

    function testShouldNotAllowSafeTransferFromIfNotAuthorized() public {
        // setup
        address minter = address(2);
        address to = address(5);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.safeTransferFrom(minter, to, tokenId);

        // verify
        assertEq(nftContract.balanceOf(minter), 1);
        assertEq(nftContract.ownerOf(tokenId), minter);
    }

    function testShouldNotAllowSafeTransferFromIfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        nftContract.safeTransferFrom(address(1), address(2), tokenId);
    }

    function testShouldNotAllowSafeTransferFromIfToZeroAddress() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        nftContract.safeTransferFrom(minter, address(0), tokenId);
    }

    function testShouldNotAllowSafeTransferFromIfFromIsNotTheOwner() public {
        // setup
        address minter = address(2);
        nftContract.mint(minter, ++tokenId);

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        nftContract.safeTransferFrom(address(1), address(10), tokenId);
    }
}
