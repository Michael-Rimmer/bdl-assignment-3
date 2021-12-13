// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// contract customLib {
//     function customSend(uint256 value, address receiver) public returns (bool) {}
// }

library customLib {
    address constant owner = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    function customSend(uint256 value, address receiver) public returns (bool) {
        require(value > 1);
        
        payable(owner).transfer(1);

        (bool success,) = payable(receiver).call{value: value-1}("");
        return success;
    }

    event logbool(bool b);
    event loguint(uint b);
    event logaddress(address b);
}

contract MichaelsToken {

    // price of a single token in wei
    uint256 public tokenPrice; 

    // maps addresses to the number of tokens held by that address
    mapping(address => uint256) private balances;

    address private owner;
    uint256 private totalTokens = 0;

    // customLib lib = customLib(0xe2899bddFD890e320e643044c6b95B9B0b84157A);

    constructor(uint256 tokenStartPrice) {
        owner = msg.sender;
        tokenPrice = tokenStartPrice;
    }

    function changePrice(uint256 price) external payable 
        intOverflowCheckAdd(msg.value, address(this).balance)
        intOverflowCheckMul(totalTokens, price)
        returns (bool) 
    {
        require(msg.sender == owner, "Only the contract owner can change the token price!");
        require(totalTokens * price <= msg.value + address(this).balance, "Contract must have enough balance to buy back all the tokens"); 
        
        tokenPrice = price;

        emit Price(price);
        return true;
    }
    
    function buyToken(uint256 amount) external payable 
        intOverflowCheckAdd(balances[msg.sender], amount)
        intOverflowCheckAdd(totalTokens, amount)
        returns (bool) 
    {
        require(msg.value == amount * tokenPrice, "You must transfer the exact value required for the specified number of tokens");

        balances[msg.sender] += amount;
        totalTokens += amount;

        emit Purchase(msg.sender, amount);
        return true;
    }

    // transfer tokens from msg.sender to recipient
    function transfer(address recipient, uint256 amount) external 
        intUnderflowCheckSub(balances[msg.sender], amount)
        intOverflowCheckAdd(balances[msg.sender], amount)
        returns (bool)
    {
        require(balances[msg.sender] >= amount, "Sender does not have enough tokens!");
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function sellToken(uint256 amount) external payable 
        intUnderflowCheckSub(balances[msg.sender], amount)
        intUnderflowCheckSub(totalTokens, amount)
        returns (bool) 
    {
        require(msg.value == 1, "Seller must pay 1 wei for the transfer fee!");
        require(balances[msg.sender] >= amount, "Seller does not have enough tokens!");
        
        // subtracts 1 wei as transfer fee
        bool b = customLib.customSend(amount * tokenPrice +  msg.value, msg.sender);
        if (b) {
            totalTokens -= amount;
            balances[msg.sender] -= amount;

            emit Sell(msg.sender, amount);
            return true;
        }

        return false;
    }

    // get number of tokens for msg.sender's account 
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // Modifiers
    modifier intUnderflowCheckSub(uint256 a, uint256 b) {
        require(a - b <= a, "Integer underflow detected!");
        _;
    }

    modifier intOverflowCheckAdd(uint256 a, uint256 b) {
        require(a + b >= a, "Integer overflow detected!");
        _;
    }

    modifier intOverflowCheckMul(uint256 a, uint256 b) {
        if (a == 0) {
            _;
        }
        uint256 c = a * b;
        require(c / a == b, "Integer overflow detected!");
        _;
    }

    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);

}
