// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../Call.sol";
import "./Hevm.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC721/ERC721.sol";

// Mock ERC20 Contract
contract TestToken is ERC20("Test Token", "TEST") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock ERC721 Contract
contract TestNFT is ERC721("Test NFT", "TEST") {
    function tokenURI(uint256) public pure override returns (string memory) {
        return "test";
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract CallTest is DSTest {
    Hevm internal hevm;
    TestToken internal token;
    TestNFT internal nft;
    Call internal call;
    address buyer;

    function setUp() public {
        hevm = Hevm(HEVM_ADDRESS);

        // Instantiate ERC20 & ERC721 contract
        nft = new TestNFT();
        token = new TestToken();

        // Mint tokens to both buyer and 'this' address which will act as the option writer
        token.mint(address(this), 100 * 10**token.decimals());
        buyer = address(0x12341234);
        token.mint(buyer, 100 * 10**token.decimals());

        // Create a new call option
        call = new Call(
            address(token),
            50 * 10**token.decimals(),
            2 * 10**token.decimals(),
            block.timestamp + 1 weeks
        );

        // Mint an NFT to 'this' address so we can use to test the call option
        nft.mint(address(this), 1);
    }

    function testDeposit() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        assertEq(nft.ownerOf(1), address(call));
    }

    function testOnlyWriterDeposit() public {
        nft.approve(address(call), 1);
        hevm.prank(address(0x999));

        hevm.expectRevert(bytes("Only the writer of the option can do this"));
        call.deposit(address(call), 1);
    }

    function testMultipleDeposit() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        hevm.expectRevert(bytes("This NFT has already been deposited"));
        call.deposit(address(nft), 1);
    }

    function testBuyOption() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        hevm.startPrank(buyer);
        token.approve(address(call), call.PREMIUM());
        call.buy();
        assertEq(call.buyer(), buyer);
    }

    function testBuyOptionOnce() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        hevm.startPrank(buyer);
        token.approve(address(call), call.PREMIUM());
        call.buy();
        hevm.stopPrank();

        hevm.prank(address(0x999));
        hevm.expectRevert(bytes("The option has already been purchased"));
        call.buy();
    }

    function testBuyAfterExpiry() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        hevm.warp(block.timestamp + 2 weeks);
        hevm.startPrank(buyer);
        token.approve(address(call), call.PREMIUM());

        hevm.expectRevert(bytes("The option has already expired"));
        call.buy();
    }

    function testBuyWithNoDeposit() public {
        hevm.expectRevert(bytes("An underlying is yet to be deposited"));
        call.buy();
    }

    function testExerciseOption() public {
        nft.approve(address(call), 1);
        call.deposit(address(nft), 1);

        hevm.startPrank(buyer);
        token.approve(address(call), call.PREMIUM());
        call.buy();
        hevm.warp(block.timestamp + 5 days);

        token.approve(address(call), call.STRIKE_PRICE());
        call.excercise();
        assertEq(nft.ownerOf(1), buyer);
    }
}
