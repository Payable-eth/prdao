
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable {
  using SafeMath for uint256;

  // Part 2 and Part 3 of the code will go here

    struct Bounty {
        address bountyOwner;
        address marketer;
        uint256 amount;
        string language;
        bool approved;
        bool completed;
        uint256 expiration;
    }


      // State Variables
      mapping (uint => Bounty) public bounties;
      mapping (uint => uint256) public bountyIdToBalance;
      uint256 public feeBalance;
      uint256 constant percentage100 = 100;
      uint256 public bountyIdCounter;

      // Event Declarations
      event LogNewBounty(uint bountyId, address bountyOwner, uint256 amount, string language);
      event LogBountyApproved(uint bountyId);
      event LogBountyConfirmed(uint bountyId);
      event LogBountyAccepted(uint bountyId, address sender);
      event LogBountyCancelled(uint bountyId);
      event LogFeesWithdrawn(uint256 fees);
      event LogFeeBalanceReset();


  // Contract Functions

  function createBounty(string memory language, uint256 amount) public {
    require(msg.value == amount, "Amount deposited must match bounty amount");

    uint bountyId = bountyIdCounter++;
    bounties[bountyId] = Bounty({
      bountyOwner: msg.sender,
      amount: amount,
      language: language,
      approved: false,
      completed: false,
      expiration: block.timestamp+ 1 weeks
    });
    bountyIdToBalance[bountyId] = amount;

    emit LogNewBounty(bountyId, msg.sender, amount, language);
  }

  function requestToAcceptBounty(uint bountyId) public {
    Bounty storage bounty = bounties[bountyId];
    require(bounty.marketer == address(0x0), "Bounty already has a marketer");
    require(now <= bounty.expiration, "Bounty has expired");

    bounty.marketer = msg.sender;

    emit LogBountyAccepted(bountyId, msg.sender);
  }

  function approveBounty(uint bountyId) public {
    Bounty storage bounty = bounties[bountyId];
    require(bounty.bountyOwner == msg.sender, "Only the bounty owner can approve a bounty");
    require(bounty.marketer != address(0), "Bounty must have a marketer before it can be approved");
    require(now <= bounty.expiration, "Bounty has expired");

    bounty.approved = true;

    emit LogBountyApproved(bountyId);
  }

    function confirmBountyFulfillment(uint bountyId) public {
      Bounty storage bounty = bounties[bountyId];
      require(bounty.marketer == msg.sender, "Only the marketer can confirm bounty fulfillment");
      require(bounty.approved, "Bounty must be approved before it can be confirmed as fulfilled");

      bountyIdToBalance[bountyId] = 0;
      feeBalance = feeBalance.add(bounty.amount.mul(5).div(percentage100));
      bounty.marketer.transfer(bounty.amount.mul(percentage100 - 5).div(percentage100));
      bounty.completed = true;

      emit LogBountyConfirmed(bountyId);
    }
  function cancelBounty(uint bountyId) public {
    Bounty storage bounty = bounties[bountyId];
    require(bounty.bountyOwner == msg.sender, "Only the bounty owner can cancel the bounty");
    require(!bounty.approved, "Approved bounties cannot be cancelled");

    bountyIdToBalance[bountyId] = 0;
    bounty.bountyOwner.transfer(bounty.amount);

    emit LogBountyCancelled(bountyId);
  }

  function withdrawFees() public onlyOwner {
    require(feeBalance > 0, "No fees to withdraw");

    uint256 fees = feeBalance;
    feeBalance = 0;

    msg.sender.transfer(fees);

    emit LogFeesWithdrawn(fees);
  }

  function resetFees() public onlyOwner {
    feeBalance = 0;

    emit LogFeeBalanceReset();
  }

}




















