
# NFT Calls

ERC721 Call Options. 

### How it works
An instance of the `Call` contract is deployed, with parameters
such as the `STRIKE_PRICE`, `PREMIUM`, `SETTLEMENT_TOKEN` and `EXPIRY` defined.
The option seller can then call `deposit` to deposit an NFT to the contract, and has the option of withdrawing the NFT, by calling `withdraw` once the `EXPIRY` has been reached.

A buyer of the option can then call `buy` to purchase the option and pay the `PREMIUM`, once the `EXPIRY` has been reached the buyer has the option of calling `excercise` which allows them to exercise their option at the `STRIKE_PRICE` thereby purchasing the NFT.


## Running & Testing

This project uses Foundry you can find more about getting setup with foundry
[here](https://github.com/gakonst/foundry). After getting setup you can run `forge build` and `forge test`, to compile and run tests respectively.


## Todo's

- [ ] Write Tests
- [ ] Refactor to allow depositing multiple NFTs and buying multiple calls
      
