// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import '../src/nft/Pepes.sol';
import 'lib/openzeppelin-contracts/contracts/interfaces/IERC721Receiver.sol';

contract TokenReceiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract PepesTest is Test {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    address public constant PRETTY_CONTRACT_OWNER = address(1000);
    bytes4 public constant IERC721_ID = 0x80ac58cd;
    bytes4 public constant IERC721_METADATA_ID = 0x5b5e139f;
    bytes4 public constant IERC721_TOKEN_RECEIVER_ID = 0x150b7a02;

    TokenReceiver tokenReceiver = new TokenReceiver();

    Pepes public pepes;

    function setUp() public {
        vm.prank(PRETTY_CONTRACT_OWNER);
        pepes = new Pepes('Pepes', 'PEP', 'https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/', 3);
    }

    function testShouldGetSuportedInterfaces() public {
        // exercise && verify
        assertTrue(pepes.supportsInterface(IERC721_ID));
        assertTrue(pepes.supportsInterface(IERC721_METADATA_ID));
        assertFalse(pepes.supportsInterface(IERC721_TOKEN_RECEIVER_ID));
    }

    function testShouldGetName() public {
        // exercise && verify
        assertEq(pepes.name(), 'Pepes');
    }

    function testShouldGetSymbol() public {
        // exercise && verify
        assertEq(pepes.symbol(), 'PEP');
    }

    function testShouldAllowMint() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), minter, 1);

        // exercise
        pepes.mint{value: 0.0001 ether}();

        // verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.ownerOf(1), minter);
    }

    function testShouldAllowMintToContractThatImplementsReceiver() public {
        // setup
        address minter = address(tokenReceiver);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), minter, 1);

        // exercise
        pepes.mint{value: 0.0001 ether}();

        // verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.ownerOf(1), minter);
    }

    function testShouldNotAllowMintToContractThatDoesNotImplementReceiver() public {
        // setup
        address minter = address(this);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);

        // vm verify
        vm.expectRevert(ERC721.NonERC721Receiver.selector);

        // exercise
        pepes.mint{value: 0.0001 ether}();
    }

    function testShouldNotAllowMintIfNotCorrectPayment() public {
        // setup
        vm.prank(address(1));

        // vm verify
        vm.expectRevert(Pepes.IncorrectPayment.selector);

        // exercise
        pepes.mint();
    }

    function testShouldNotAllowMintIfMintedOut() public {
        // setup
        address minterOne = address(1);
        address minterTwo = address(2);
        address minterThree = address(3);
        address minterFour = address(4);
        vm.deal(minterOne, 0.5 ether);
        vm.deal(minterTwo, 0.5 ether);
        vm.deal(minterThree, 0.5 ether);
        vm.deal(minterFour, 0.5 ether);
        vm.prank(minterOne);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minterTwo);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minterThree);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minterFour);

        // vm verify
        vm.expectRevert(Pepes.NoMoreSupply.selector);

        // exercise
        pepes.mint{value: 0.0001 ether}();
    }

    function testShouldNotAllowMintToZeroAddress() public {
        // setup
        vm.prank(address(0));
        vm.deal(address(0), 0.5 ether);

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        pepes.mint{value: 0.0001 ether}();
    }

    function testShouldGetTokenURI() public {
        // setup
        vm.prank(address(2));
        vm.deal(address(2), 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // exercise && verify
        assertEq(pepes.tokenURI(1), 'https://ipfs.io/ipfs/QmX6zL25DrVSGuLzqZDtp2ex9GoKdop9W7mUAxXDUAzYJH/1');
    }

    function testShouldNotGetTokenURIOfInvalidToken() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        pepes.tokenURI(1);
    }

    function testShouldGetTheBalanceOfAnOwner() public {
        // setup
        address minter = address(2);
        vm.prank(minter);
        vm.deal(minter, 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // exercise && verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.balanceOf(address(3)), 0);
    }

    function testShouldNotGetTheBalanceOfZeroAddress() public {
        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        pepes.balanceOf(address(0));
    }

    function testShouldGetOwnerOfToken() public {
        // setup
        address minter = address(2);
        vm.prank(minter);
        vm.deal(minter, 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // exercise && verify
        assertEq(pepes.ownerOf(1), minter);
    }

    function testShouldNotGetOwnerOfInvalidToken() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        pepes.ownerOf(1);
    }

    function testShouldAllowBurn() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, address(0), 1);

        // 1º exercise
        pepes.burn(1);

        // verify
        assertEq(pepes.balanceOf(minter), 0);

        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // 2º exercise
        pepes.ownerOf(1);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowBurnOfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        pepes.burn(1);
    }

    function testShouldNotAllowBurnIfNotOwner() public {
        // setup
        vm.prank(address(1));
        vm.deal(address(1), 0.5 ether);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(address(2));

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.burn(1);
    }

    function testShouldGetApproved() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();

        // exercise && verify
        assertEq(pepes.getApproved(1), address(0));
    }

    function testShouldNotGetApprovedForInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise && verify
        pepes.getApproved(1);
    }

    function testShouldAllowOwnerToApprove() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, address(this), 1);

        // exercise
        pepes.approve(address(this), 1);

        // verify
        assertEq(pepes.getApproved(1), address(this));

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowOwnerToRevokeApprove() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, address(0), 1);

        // exercise
        pepes.approve(address(0), 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowOperatorToApprove() public {
        // setup
        address operator = address(10);
        address minter = address(2);
        address approved = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minter);
        pepes.setApprovalForAll(operator, true);

        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Approval(minter, approved, 1);

        // exercise
        pepes.approve(approved, 1);

        // verify
        assertEq(pepes.getApproved(1), approved);
    }

    function testShouldNotAllowToApproveIfNotAuthorized() public {
        // setup
        vm.prank(address(2));
        vm.deal(address(2), 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.approve(address(this), 1);
    }

    function testShouldNotAllowToApproveIfTargetIsMsgSender() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.SelfTarget.selector);

        // exercise
        pepes.approve(minter, 1);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowSetupApprovalForAll() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(minter, operator, true);

        // exercise
        pepes.setApprovalForAll(operator, true);

        // verify
        assertTrue(pepes.isApprovedForAll(minter, operator));

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowToRevokeApprovalForAll() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(minter, operator, false);

        // exercise
        pepes.setApprovalForAll(operator, false);

        // verify
        assertFalse(pepes.isApprovedForAll(minter, operator));

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowSetupApprovalForAllIfNotAnOwner() public {
        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.setApprovalForAll(address(this), true);
    }

    function testShouldNotAllowToSetupApprovalForAllIfSelfTarget() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.SelfTarget.selector);

        // exercise
        pepes.setApprovalForAll(minter, true);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowToSetupApprovalForAllIfZeroAddress() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        pepes.setApprovalForAll(address(0), true);

        // cleanup
        vm.stopPrank();
    }

    function testShouldGetApprovedForALl() public {
        // setup
        address minter = address(2);
        address operator = address(5);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();
        pepes.setApprovalForAll(operator, true);

        // exercise && verify
        assertTrue(pepes.isApprovedForAll(minter, operator));
        assertFalse(pepes.isApprovedForAll(minter, address(4)));
        assertFalse(pepes.isApprovedForAll(operator, minter));
        assertFalse(pepes.isApprovedForAll(address(0), address(7)));

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowTransferFromIfOnwer() public {
        // setup
        address minter = address(2);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.transferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);

        // cleanup
        vm.stopPrank();
    }

    function testShouldAllowTransferFromIfApproved() public {
        // setup
        address minter = address(2);
        address approved = address(3);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minter);
        pepes.approve(approved, 1);
        vm.prank(approved);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.transferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);
    }

    function testShouldAllowTransferFromIfAllowedOperator() public {
        // setup
        address minter = address(2);
        address operator = address(3);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minter);
        pepes.setApprovalForAll(operator, true);
        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.transferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);
    }

    function testShouldNotAllowTransferFromIfNotAuthorized() public {
        // setup
        address minter = address(2);
        address to = address(5);
        vm.prank(minter);
        vm.deal(minter, 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.transferFrom(minter, to, 1);

        // verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.ownerOf(1), minter);
    }

    function testShouldNotAllowTransferFromIfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        pepes.transferFrom(address(1), address(2), 1);
    }

    function testShouldNotAllowTransferFromIfToZeroAddress() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        pepes.transferFrom(minter, address(0), 1);
    }

    function testShouldNotAllowTransferFromIfFromIsNotTheOwner() public {
        // setup
        address minter = address(2);
        vm.prank(minter);
        vm.deal(minter, 0.5 ether);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.transferFrom(address(1), address(10), 1);
    }

    function testShouldAllowSafeTransferFromIfOnwer() public {
        // setup
        address minter = address(2);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.safeTransferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);
    }

    function testShouldAllowSafeTransferFromIfApproved() public {
        // setup
        address minter = address(2);
        address approved = address(3);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minter);
        pepes.approve(approved, 1);
        vm.prank(approved);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.safeTransferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);
    }

    function testShouldAllowSafeTransferFromIfAllowedOperator() public {
        // setup
        address minter = address(2);
        address operator = address(3);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();
        vm.prank(minter);
        pepes.setApprovalForAll(operator, true);
        vm.prank(operator);

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.safeTransferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);
    }

    function testShouldAllowSafeTransferFromToATokenReceiverContract() public {
        // setup
        address minter = address(2);
        address to = address(tokenReceiver);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectEmit(true, true, true, true);
        emit Transfer(minter, to, 1);

        // exercise
        pepes.safeTransferFrom(minter, to, 1);

        // verify
        assertEq(pepes.getApproved(1), address(0));
        assertEq(pepes.balanceOf(minter), 0);
        assertEq(pepes.balanceOf(to), 1);
        assertEq(pepes.ownerOf(1), to);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowSafeTransferFromToContractThatDoesNotImplementTokenReceiver() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.startPrank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.NonERC721Receiver.selector);

        // exercise
        pepes.safeTransferFrom(minter, address(this), 1);

        // verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.ownerOf(1), minter);

        // cleanup
        vm.stopPrank();
    }

    function testShouldNotAllowSafeTransferFromIfNotAuthorized() public {
        // setup
        address minter = address(2);
        address to = address(5);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.safeTransferFrom(minter, to, 1);

        // verify
        assertEq(pepes.balanceOf(minter), 1);
        assertEq(pepes.ownerOf(1), minter);
    }

    function testShouldNotAllowSafeTransferFromIfInvalidNft() public {
        // vm verify
        vm.expectRevert(ERC721.IsInvalidNft.selector);

        // exercise
        pepes.safeTransferFrom(address(1), address(2), 1);
    }

    function testShouldNotAllowSafeTransferFromIfToZeroAddress() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.IsZeroAddress.selector);

        // exercise
        pepes.safeTransferFrom(minter, address(0), 1);
    }

    function testShouldNotAllowSafeTransferFromIfFromIsNotTheOwner() public {
        // setup
        address minter = address(2);
        vm.deal(minter, 0.5 ether);
        vm.prank(minter);
        pepes.mint{value: 0.0001 ether}();

        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.safeTransferFrom(address(1), address(10), 1);
    }

    function testShouldAllowToWithdrawFunds() public {
        // setup
        vm.deal(address(pepes), 1 ether);
        vm.prank(PRETTY_CONTRACT_OWNER);

        // exercise
        pepes.withdraw();

        // verify
        assertEq(PRETTY_CONTRACT_OWNER.balance, 1 ether);
    }

    function testShouldNotAllowToWithdrawFundsIfNotOwner() public {
        // vm verify
        vm.expectRevert(ERC721.Unauthorized.selector);

        // exercise
        pepes.withdraw();
    }
}
