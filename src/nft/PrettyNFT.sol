// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ERC721.sol';

contract PrettyNFT is ERC721 {
    error IncorrectPayment();
    error NoMoreSupply();

    uint8 public immutable MAX_SUPPLY;
    uint8 private tokenIdTracker;
    address payable public owner;
    uint256 private constant MINT_PRICE = 0.0001 ether;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier isCorrectPayment() {
        _assertIsCorrectPayment();
        _;
    }

    modifier itHasSupply() {
        _assertItHasSupply();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint8 maxSupply
    ) ERC721(name, symbol, baseURI) {
        owner = payable(msg.sender);
        MAX_SUPPLY = maxSupply;
    }

    /* ---------- EXTERNAL ----------  */

    /**
     * @notice Withdraw contract funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }

    /**
     * @notice Mint a Pretty NFT
     */
    function mint() external payable isCorrectPayment itHasSupply {
        _safeMint(msg.sender, ++tokenIdTracker);
    }

    /**
     * @notice Burn `tokenId`
     *
     * @param tokenId The id of the nft
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Check if payment if valid
     * @dev Throws unless `msg.value` is equal to `MINT_PRICE`
     */
    function _assertIsCorrectPayment() private view {
        if (msg.value == MINT_PRICE) {
            return;
        }

        revert IncorrectPayment();
    }

    /**
     * @notice Check if total supply has been reached
     * @dev Throws unless the next token id is not bigger than `MAX_SUPPLY`
     */
    function _assertItHasSupply() private view {
        if (tokenIdTracker + 1 <= MAX_SUPPLY) {
            return;
        }

        revert NoMoreSupply();
    }
}
