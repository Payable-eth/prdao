//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// Escrow contract that allows a bounty owner to create a bounty, deposit the funds for the bounty, and approve a request from a marketer to accept the bounty
// Once the bounty owner approves the marketer, the funds are locked until both the bounty owner and the marketer confirm the bounty has been fulfilled
// Onces both parties confirm the bounty is fulfilled, the funds are paid to the marketer and the contract collects a 5% fee
// The bounty owner can also cancel the bounty and be refunded the funds deposited
// The contract owner can withdraw the 5% fees collected
contract Escrow is Ownable {
    using SafeMath for uint;


    // Struct to represent a bounty
    struct Bounty {
        bool confirmed;
        uint expirationTime;
        address bountyOwner;
        address marketer;
        uint amount;
        address payable language;
    }

    // Mapping from bounty IDs to bounties
    mapping(uint => Bounty) public bounties;

    // Mapping from bounty IDs to token balances
    mapping(uint => uint) public bountyTokenBalances;

    // Balance of fees collected by the contract
    uint public feeBalance;

     // Counter to keep track of the number of bounties created
    uint public bountyCount;

    // Events
    event NewBounty(uint bountyId, address sender, uint amount, uint expirationTime, address language, uint tokenAmount);
    event BountyAccepted(uint bountyId, address marketer);
    event BountyApproved(uint bountyId, address bountyOwner);
    event BountyCancelled(uint bountyId, address bountyOwner);
    event BountyFulfilled(uint bountyId, address marketer);
    event FeesWithdrawn(uint feeBalance);
    event FeesReset();

   function createBounty(uint expirationTime, uint amount, address payable language, uint tokenAmount) public {
    // Check that the bounty amount is greater than the contract fee (5% of the amount)
    require(amount.mul(95).div(100) > 0, "Bounty amount must be greater than the contract fee");

    // Generate a unique ID for the bounty
    uint bountyId = address(this).balance.add(bountyCount);
    bountyCount++;

    // Create a new bounty struct
    Bounty memory bounty = Bounty({
        confirmed: false,
        expirationTime: expirationTime,
        bountyOwner: msg.sender,
        marketer: address(0),
        amount: amount,
        language: language
    });

    // Save the bounty and token balance
    bounties[bountyId] = bounty;
    bountyTokenBalances[bountyId] = tokenAmount;

    // Transfer the bounty amount and token balances to the contract
    if (payable(msg.sender).send(amount)) {
        emit NewBounty(bountyId, msg.sender, amount, expirationTime, language, tokenAmount);
    } else {
        revert("Failed to transfer bounty amount");
    }
    
    require(payable(language).send(tokenAmount), "Failed to transfer token balance");
}


// Allows a marketer to request to accept a bounty
function requestToAcceptBounty(uint bountyId) public {
    // Get the bounty
    Bounty storage bounty = bounties[bountyId];

    // Check that the bounty has not been cancelled, that the expiration time has not been reached, and that the caller is not the bounty owner
    require(!bounty.confirmed, "Bounty has already been confirmed");
    require(bounty.expirationTime >= block.timestamp, "Bounty has expired");
    require(bounty.bountyOwner != msg.sender, "Caller is the bounty owner");

    // Set the marketer to the caller
    bounty.marketer = msg.sender;

            // Emit the BountyAccepted event
        emit BountyAccepted(bountyId, msg.sender);
    }

    // Modifier to check that a bounty has not been confirmed
    modifier notConfirmed(uint bountyId) {
        require(!bounties[bountyId].confirmed, "Bounty has already been confirmed");
        _;
    }

    // Allows the bounty owner to approve a request to accept a bounty
    function approveBounty(uint bountyId) public notConfirmed(bountyId) {
        // Get the bounty
        Bounty storage bounty = bounties[bountyId];

        // Check that the bounty has not been cancelled, that the expiration time has not been reached, and that the caller is the bounty owner
        require(bounty.expirationTime >= block.timestamp, "Bounty has expired");
        require(bounty.bountyOwner == msg.sender, "Caller is not the bounty owner");

        // Emit the BountyApproved event
        emit BountyApproved(bountyId, msg.sender);
    }

        // Confirm that the bounty has been fulfilled by both the bounty owner and the marketer
function confirmFulfillment(uint bountyId) public {
    // Get the bounty
    Bounty storage bounty = bounties[bountyId];

    // Check that the caller is the bounty owner or the marketer
    require(bounty.bountyOwner == msg.sender || bounty.marketer == msg.sender, "Caller is not the bounty owner or marketer");

    // Check that the bounty has been confirmed and that the expiration time has not been reached
    require(bounty.confirmed, "Bounty has not been confirmed");
    require(bounty.expirationTime >= block.timestamp, "Bounty has expired");

    // Transfer the bounty amount minus the fee to the marketer
    uint fee = bounty.amount.mul(5).div(100);
    uint amountToTransfer = bounty.amount.sub(fee);
    require (amountToTransfer > 0, "Bounty amount is not enough to cover the fee");
    require (address(this).balance >= amountToTransfer, "Contract balance is not enough to cover the transfer");
    payable(bounty.marketer).transfer(amountToTransfer);

    // Update the fee balance
    feeBalance = feeBalance.add(fee);

    // Emit the BountyFulfilled event
    emit BountyFulfilled(bountyId, bounty.marketer);
}


    // Allows the contract owner to withdraw the fees collected
    function withdrawFees() public onlyOwner {
        // Get the current fee balance
        uint currentFeeBalance = feeBalance;

        // Reset the fee balance
        feeBalance = 0;

        // Transfer the current fee balance to the contract owner
        require(payable(msg.sender).send(currentFeeBalance), "Failed to transfer fees to contract owner");

        // Emit the FeesWithdrawn event
        emit FeesWithdrawn(currentFeeBalance);
    }

    // Allows the contract owner to reset the fees collected
    function resetFees() public onlyOwner {
        // Reset the fee balance
        feeBalance = 0;

        // Emit the FeesReset event
        emit FeesReset();
    }
}

