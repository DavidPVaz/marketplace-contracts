// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import 'lib/openzeppelin-contracts/contracts/interfaces/IERC721Metadata.sol';
import 'lib/openzeppelin-contracts/contracts/interfaces/IERC721Receiver.sol';

abstract contract ERC721 is IERC721Metadata {
    using Strings for uint256;

    error IsZeroAddress();
    error IsInvalidNft();
    error Unauthorized();
    error SelfTarget();
    error NonERC721Receiver();

    string private _baseURI;
    string private _name;
    string private _symbol;

    // token id -> owner
    mapping(uint256 => address) private _owners;
    // owner -> amount of tokens
    mapping(address => uint256) private _balances;
    // owner -> operator -> authorized
    mapping(address => mapping(address => bool)) private _operators;
    // token id -> approved
    mapping(uint256 => address) private _approvals;

    modifier isNotZeroAddress(address target) {
        _assertIsNotZeroAddress(target);
        _;
    }

    modifier isValidNft(uint256 tokenId) {
        _assertIsValidNft(tokenId);
        _;
    }

    modifier itCanApprove(uint256 tokenId) {
        _assertItCanApprove(tokenId);
        _;
    }

    modifier itCanTransfer(uint256 tokenId) {
        _assertItCanTransfer(tokenId);
        _;
    }

    modifier isAnOwner() {
        _assertIsAnOwner();
        _;
    }

    modifier isNotSelf(address target) {
        _assertIsNotSelf(target);
        _;
    }

    modifier isTheOwner(address target, uint256 tokenId) {
        _assertIsTheOwner(target, tokenId);
        _;
    }

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory baseURI
    ) {
        _name = nftName;
        _symbol = nftSymbol;
        _baseURI = baseURI;
    }

    /** @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
     *
     * @return bool `true` if the contract implements `interfaceId` and `interfaceId` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     * 3986. The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
     * @param tokenId The identifier for an NFT
     */
    function tokenURI(uint256 tokenId) external view override isValidNft(tokenId) returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     * function throws for queries about the zero address.
     *
     * @param owner An address for whom to query the balance
     *
     * @return uint256 number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address owner) external view override isNotZeroAddress(owner) returns (uint256) {
        return _balances[owner];
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     *
     * @param tokenId The identifier for an NFT
     *
     * @return address address of the owner of the NFT
     */
    function ownerOf(uint256 tokenId) external view override isValidNft(tokenId) returns (address) {
        return _owners[tokenId];
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     * operator, or the approved address for this NFT. Throws if `from` is
     * not the current owner. Throws if `to` is the zero address. Throws if
     * `tokenId` is not a valid NFT. When transfer is complete, this function
     * checks if `to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     **/
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override isValidNft(tokenId) isNotZeroAddress(to) isTheOwner(from, tokenId) itCanTransfer(tokenId) {
        _transfer(from, to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, from, tokenId, data);
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter except
     * this function just sets data to "".
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override isValidNft(tokenId) isNotZeroAddress(to) isTheOwner(from, tokenId) itCanTransfer(tokenId) {
        _transfer(from, to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, from, tokenId, '');
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     * TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     * operator, or the approved address for this NFT. Throws if `from` is
     * not the current owner. Throws if `to` is the zero address. Throws if `tokenId` is not a valid NFT.
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override isValidNft(tokenId) isNotZeroAddress(to) isTheOwner(from, tokenId) itCanTransfer(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @notice Change or reaffirm the approved address for an NFT.
     * @dev The zero address indicates there is no approved address.
     * Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
     *
     * @param approved The new approved NFT controller
     * @param tokenId The NFT to approve
     */
    function approve(address approved, uint256 tokenId) external override itCanApprove(tokenId) isNotSelf(approved) {
        _approvals[tokenId] = approved;

        emit Approval(_owners[tokenId], approved, tokenId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
     *
     * @param operator address to add to the set of authorized operators
     * @param approved true if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address operator, bool approved)
        external
        override
        isAnOwner
        isNotSelf(operator)
        isNotZeroAddress(operator)
    {
        _operators[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `tokenId` is not a valid NFT.
     *
     * @param tokenId The NFT to find the approved address for
     *
     * @return address approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 tokenId) external view override isValidNft(tokenId) returns (address) {
        return _approvals[tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     *
     * @param owner The address that owns the NFTs
     * @param operator The address that acts on behalf of the owner
     *
     * @return bool true if `operator` is an approved operator for `owner`, false otherwise
     */
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operators[owner][operator];
    }

    /* ---------- INTERNAL ---------- */

    /**
     * @notice Safely mint a new nft
     * @dev Throws unless `to` is not the zero address and if being a contract, it does implement ERC721Receiver
     *
     * @param to address that will receive the nft
     * @param tokenId The id of the nft
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, address(0), tokenId, '');
    }

    /**
     * @notice Burn `tokenId`
     * @dev The approval is cleared when the token is burned. Throws if `tokenId` is not a valid NFT
     * or if `msg.sender` is not the current owner
     *
     * @param tokenId The id of the nft
     */
    function _burn(uint256 tokenId) internal isValidNft(tokenId) isTheOwner(msg.sender, tokenId) {
        delete _approvals[tokenId];
        delete _owners[tokenId];
        unchecked {
            --_balances[msg.sender];
        }

        emit Transfer(msg.sender, address(0), tokenId);
    }

    /* ---------- PRIVATE ---------- */

    /**
     * @notice Check if a contract implements `onERC721Received`
     * @dev Throws unless `to` implements `onERC721Received`
     *
     * @param to The address of the contract
     * @param previousOwner The address of previous owner
     * @param tokenId The NFT to transfer
     * @param data The calldata
     */
    function _assertIsERC721Receiver(
        address to,
        address previousOwner,
        uint256 tokenId,
        bytes memory data
    ) private {
        (, bytes memory result) = to.call(
            abi.encodeWithSelector(IERC721Receiver.onERC721Received.selector, msg.sender, previousOwner, tokenId, data)
        );

        if (bytes4(result) == IERC721Receiver.onERC721Received.selector) {
            return;
        }

        revert NonERC721Receiver();
    }

    /**
     * @notice Mint a new nft
     * @dev Throws if `to` is the zero address.
     *
     * @param to address that will receive the nft
     * @param tokenId The id of the nft
     */
    function _mint(address to, uint256 tokenId) private isNotZeroAddress(to) {
        _owners[tokenId] = to;
        unchecked {
            ++_balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Check if a given address is a contract
     *
     * @param target The address to verify
     *
     * @return bool true if `target` is a contract, false otherwise
     */
    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }

    /**
     * @notice Transfer ownership of `tokenId` to `to` address
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        delete _approvals[tokenId];
        _owners[tokenId] = to;
        unchecked {
            --_balances[from];
            ++_balances[to];
        }

        emit Transfer(from, to, tokenId);
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Check if an address is the zero address
     * @dev Throws unless `target` is not the zero address
     *
     * @param target The address to verify
     */
    function _assertIsNotZeroAddress(address target) private pure {
        if (target != address(0)) {
            return;
        }

        revert IsZeroAddress();
    }

    /**
     * @notice Check if a NFT is valid
     * @dev Throws unless `tokenId` exists
     *
     * @param tokenId The NFT id to verify
     */
    function _assertIsValidNft(uint256 tokenId) private view {
        if (_owners[tokenId] != address(0)) {
            return;
        }

        revert IsInvalidNft();
    }

    /**
     * @notice Check if a `msg.sender` is a holder of NFT
     * @dev Throws unless `msg.sender` is a holder
     */
    function _assertIsAnOwner() private view {
        if (_balances[msg.sender] > 0) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `msg.sender` can approve a certain NFT
     * @dev Throws unless `msg.sender` is the NFT owner or a valid operator
     *
     * @param tokenId The NFT id to verify
     */
    function _assertItCanApprove(uint256 tokenId) private view {
        address owner = _owners[tokenId];

        if (msg.sender == owner || _operators[owner][msg.sender]) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `msg.sender` can transfer a certain NFT
     * @dev Throws unless `msg.sender` is the NFT owner, a valid operator or an approved address
     *
     * @param tokenId The NFT id to verify
     */
    function _assertItCanTransfer(uint256 tokenId) private view {
        address owner = _owners[tokenId];

        if (msg.sender == owner || _operators[owner][msg.sender] || msg.sender == _approvals[tokenId]) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `target` is the holder of a specific NFT
     * @dev Throws unless `target` is the NFT owner of `tokenId` and `target` is not the zero address
     *
     * @param target The address to verify
     * @param tokenId The NFT id to verify
     */
    function _assertIsTheOwner(address target, uint256 tokenId) private view {
        if (target != address(0) && _owners[tokenId] == target) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `target` is not the `msg.sender`
     * @dev Throws unless `target` is not the `msg.sender`
     *
     * @param target The address to verify
     */
    function _assertIsNotSelf(address target) private view {
        if (target != msg.sender) {
            return;
        }

        revert SelfTarget();
    }
}
