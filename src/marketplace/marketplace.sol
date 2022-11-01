// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Marketplace {
    event Listed(address indexed collection, address indexed seller, uint256 nftId);
    event CancelListing(address indexed collection, address indexed seller, uint256 nftId);
    event Bought(address indexed collection, address indexed buyer, uint256 nftId, uint256 price);

    error Unauthorized();
    error Locked();
    error AlreadyListed();
    error InvalidCollection();
    error NotListed();
    error InvalidPayment();

    struct Collection {
        bool listed;
        address creator;
    }

    struct Listing {
        bool active;
        address seller;
        uint256 price;
    }

    bool private lock;
    uint8 public percentageFee;
    address payable public owner;

    // Listed collections on marketplace - contract addresses
    Collection[] private collections;
    // collection contract address -> Collection
    mapping(address => Collection) private listedCollections;

    // collection contract address -> nftId -> Listing
    mapping(address => mapping(uint256 => Listing)) private listings;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier locked() {
        if (lock) {
            revert Locked();
        }
        lock = true;
        _;
        lock = false;
    }

    constructor(uint8 fee) {
        owner = payable(msg.sender);
        percentageFee = fee;
    }

    /**
     * @notice Set marketplace fee
     *
     * @param fee The new marketplace fee
     */
    function setFee(uint8 fee) external onlyOwner {
        percentageFee = fee;
    }

    /**
     * @notice Withdraw marketplace funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success);
    }

    /**
     * @notice Gets marketplace listed collections.
     *
     * @return Collection[] the list of collections
     */
    function getCollections() external view returns (Collection[] memory) {
        return collections;
    }

    /**
     * @notice Allows a `collection` owner to list his collection in marketplace
     *
     * @param collection The contract address of the collection
     */
    function listInMarketplace(address collection) external locked {
        _assertIsTheCollectionOwner(collection);
        _assertIsNotListed(collection);

        listedCollections[collection] = collections.push() = Collection({listed: true, creator: msg.sender});
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     * @param price The listing price
     */
    function list(
        address collection,
        uint256 nftId,
        uint256 price
    ) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwner(collection, nftId);
        _assertNftIsNotListed(collection, nftId);

        _transferNftToMarketplace(collection, nftId);
        listings[collection][nftId] = Listing({active: true, seller: msg.sender, price: price});

        emit Listed(collection, msg.sender, nftId);
    }

    /**
     * @notice Allow an nft owner to cancel the listing of his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function cancelListing(address collection, uint256 nftId) external locked {
        _assertIsValidCollection(collection);
        _assertIsNftOwnerOnCancel(collection, nftId);
        _assertNftIsListed(collection, nftId);

        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        emit CancelListing(collection, msg.sender, nftId);
    }

    /**
     * @notice Allow an nft owner to list his nft
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function buy(address collection, uint256 nftId) external payable locked {
        _assertIsValidCollection(collection);
        _assertNftIsListed(collection, nftId);
        _assertPaymentIsCorrect(collection, nftId);

        Listing memory listing = listings[collection][nftId];
        delete listings[collection][nftId];
        _transferNftToUser(collection, nftId);

        (bool success, ) = payable(listing.seller).call{value: _calculatePayout(listing.price)}('');
        require(success);

        emit Bought(collection, msg.sender, nftId, listing.price);
    }

    /* ---------- PRIVATE ---------- */
    /**
     * @notice Transfer `nftId` from `msg.sender` to marketplace
     * @dev It needs to be approved before call
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToMarketplace(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('transferFrom(address,address,uint256)', msg.sender, address(this), nftId)
        );
        require(success);
    }

    /**
     * @notice Transfer `nftId` from marketplace to `msg.sender`
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _transferNftToUser(address collection, uint256 nftId) private {
        (bool success, ) = collection.call(
            abi.encodeWithSignature('safeTransferFrom(address,address,uint256)', address(this), msg.sender, nftId)
        );
        require(success);
    }

    /**
     * @notice Calculate the payout to the seller -> Price - Fee
     *
     * @param price the price of the nft
     *
     * @return uint256 the payout amount to seller minus  marketplace fee
     */
    function _calculatePayout(uint256 price) private view returns (uint256) {
        return price - (price * percentageFee) / 100;
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Assert a contract owner
     * @dev Throws unless `msg.sender` is the `collection` owner
     *
     * @param collection The contract address of the collection
     */
    function _assertIsTheCollectionOwner(address collection) private {
        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('owner()'));
        require(success);

        if (abi.decode(result, (address)) == msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that a collection is still not listed in the marketplace
     * @dev Throws unless `collection` is not listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsNotListed(address collection) private view {
        if (!listedCollections[collection].listed) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that a collection is valid - listed in the marketplace
     * @dev Throws unless `collection` is listed
     *
     * @param collection The contract address of the collection
     */
    function _assertIsValidCollection(address collection) private view {
        if (listedCollections[collection].listed) {
            return;
        }

        revert InvalidCollection();
    }

    /**
     * @notice Assert that `msg.sender` is the owner of `nftId` from `collecton`
     * @dev Throws unless `msg.sender` is the `nftId` owner
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNftOwner(address collection, uint256 nftId) private {
        (bool success, bytes memory result) = collection.call(abi.encodeWithSignature('ownerOf(uint256)', nftId));
        require(success);

        if (abi.decode(result, (address)) == msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `nftId` is not already listed
     * @dev Throws unless `nftId` is not listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsNotListed(address collection, uint256 nftId) private view {
        if (!listings[collection][nftId].active) {
            return;
        }

        revert AlreadyListed();
    }

    /**
     * @notice Assert that `msg.sender` is the seller of `nftId` listing
     * @dev Throws unless `msg.sender` is the `nftId` seller
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertIsNftOwnerOnCancel(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].seller == msg.sender) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Assert that `nftId` is listed
     * @dev Throws unless `nftId` is listed
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertNftIsListed(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].active) {
            return;
        }

        revert NotListed();
    }

    /**
     * @notice Assert that `msg.value` is equal to the listing price
     * @dev Throws unless `msg.value` is equal to listing price
     *
     * @param collection The contract address of the collection
     * @param nftId The NFT ID
     */
    function _assertPaymentIsCorrect(address collection, uint256 nftId) private view {
        if (listings[collection][nftId].price == msg.value) {
            return;
        }

        revert InvalidPayment();
    }
}
