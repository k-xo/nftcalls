// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/token/ERC721/IERC721.sol";

/// @title NFT Call
/// @author k-xo
/// @notice Simple implementation of a call option for NFTs

contract Call is IERC721Receiver {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Storage & Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the underlying NFT contract
    address public underlying;

    /// @notice specfic tokenId of the NFT the seller of the call owns
    uint256 public tokenId;

    /// @notice address of the creator / seller of the call option
    address public creator;

    /// @notice address of the buyer of the call option
    address public buyer;

    /// @notice mapping to check whether an NFT has already been deposited to the contract
    bool public underlyingDeposited;

    /// @notice strike price in which the option is excercisbale
    uint256 public immutable STRIKE_PRICE;

    /// @notice the premium to be paid for the option
    uint256 public immutable PREMIUM;

    ///@notice expiry of contract
    uint256 public immutable EXPIRY;

    /// @notice the token in which the option is settled / denominated in.
    address public immutable SETTLEMENT_TOKEN;

    /**
     * @notice initializes the values for the call option
     * @param strikePrice strike price
     * @param premium premium for option
     * @param settlmentToken - quote token for denominations
     * @param expiry the expiry date for the option
     */
    constructor(
        address settlmentToken,
        uint256 strikePrice,
        uint256 premium,
        uint256 expiry
    ) {
        creator = msg.sender;
        STRIKE_PRICE = strikePrice;
        PREMIUM = premium;
        SETTLEMENT_TOKEN = settlmentToken;
        EXPIRY = expiry;
    }

    /// @notice Deposits an NFT to the contract
    /// @param _underlying the address of the NFT contract that will act as the underlying
    /// @param _tokenId the ID of the token the creator wants to deposit
    // maybe move this to the constructor & do it all in one step(?)
    function deposit(address _underlying, uint256 _tokenId) external {
        require(msg.sender == creator);
        require(!underlyingDeposited, "This NFT has already been deposited");

        underlying = _underlying;
        tokenId = _tokenId;
        underlyingDeposited = true;

        IERC721(_underlying).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
    }

    /// @notice Allows the creator of the option to withdraw the NFT if the expiry date has passed
    function withdraw() external {
        require(msg.sender == creator);
        require(block.timestamp <= EXPIRY, "The option has not expired");

        IERC721(underlying).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        underlyingDeposited = false;
    }

    /// @notice allows the buyer to buy the option
    function buy() external {
        require(underlyingDeposited, "An underlying is yet to be deposited");
        require(block.timestamp < EXPIRY, "The option has already expired");

        IERC20(SETTLEMENT_TOKEN).safeTransferFrom(msg.sender, creator, PREMIUM);
        buyer = msg.sender;
    }

    ///@notice allows the buyer to exercise their option
    function excercise() external {
        require(block.timestamp < EXPIRY, "The option has already expired");
        require(msg.sender == buyer, "Only buyer can exercise option");

        IERC20(SETTLEMENT_TOKEN).safeTransferFrom(
            msg.sender,
            creator,
            STRIKE_PRICE
        );

        IERC721(underlying).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
