const { expect } = require("chai");
require("hardhat-chai-matchers");
const { solidity } = require("hardhat-ethers");
const { mocha } = require("hardhat-mocha");

describe("Bounty Contract", function () {
  this.timeout(10000);
  let bounty;

  before(async () => {
    bounty = await solidity("Bounty.sol");
  });

  describe("Creation of a bounty", () => {
    it("Should create a bounty", async () => {
      const instance = await bounty.new();
      expect(instance.address).to.not.be.null;
    });
  });
});
const { expect } = require("hardhat-chai-matchers");
const { ethers } = require("hardhat-ethers");

describe("Bounty Contract - Request to accept a bounty", function () {
  let bountyInstance;
  let hunter;
  let requester;

  before(async function () {
    // Get contract instance
    bountyInstance = await ethers.getContractAt("Bounty", <contract_address>);
    // Get signer accounts
    hunter = await ethers.getSigner(<hunter_index>);
    requester = await ethers.getSigner(<requester_index>);
  });

  it("Should allow the requester to request to accept a bounty", async function () {
    const result = await bountyInstance.requestToAcceptBounty(<bounty_id>, {
      from: requester,
    });

    expect(result.logs[0].event).to.eq("RequestToAcceptBounty");
    expect(result.logs[0].args.requester).to.eq(requester.address);
    expect(result.logs[0].args.bountyId).to.eq(<bounty_id>);
  });
});
describe("Bounty Contract - Approval Test", function() {
  it("should allow an approved account to approve a bounty", async function() {
    // Retrieve the bounty contract instance
    const bountyInstance = await Bounty.deployed();

    // Check if the bounty is approved
    const isApproved = await bountyInstance.isApproved();
    assert.isFalse(isApproved, "Bounty should not be approved before approval");

    // Get the approver address
    const approver = (await bountyInstance.approver()).toString();
    assert.equal(approver, constants.AddressZero, "Approver should be 0 address before approval");

    // Approve the bounty
    await bountyInstance.approve({ from: owner });

    // Check if the bounty is approved after approval
    const isApprovedAfter = await bountyInstance.isApproved();
    assert.isTrue(isApprovedAfter, "Bounty should be approved after approval");

    // Get the approver address after approval
    const approverAfter = (await bountyInstance.approver()).toString();
    assert.equal(approverAfter, owner, "Approver should be owner after approval");
  });
});
describe("Test the cancellation of a bounty", async function () {
    let bountyId;
    before(async function () {
        const result = await bountyInstance.createBounty(
            "Bounty Title",
            "Bounty Description",
            100,
            { from: owner }
        );
        bountyId = result.logs[0].args.bountyId.toNumber();
    });
    it("Should cancel the bounty successfully", async function () {
        await bountyInstance.cancelBounty(bountyId, { from: owner });
        const bounty = await bountyInstance.bounties(bountyId);
        assert.equal(bounty.status, BOUNTY_STATUS_CANCELLED, "The bounty should be cancelled");
    });
    it("Should fail to cancel the bounty if not the owner", async function () {
        try {
            await bountyInstance.cancelBounty(bountyId, { from: other });
            assert.fail("The cancelBounty function should throw an error");
        } catch (error) {
            assert.include(
                error.message,
                "revert",
                "The cancelBounty function should throw a revert error"
            );
        }
    });
});
  it("Test the withdrawal of fees collected by the contract", async () => {
    // Step 1: Get the initial balance of the contract
    const initialBalance = await web3.eth.getBalance(bountyContract.address);
  
    // Step 2: Get the amount of fees collected by the contract
    const feesCollected = await bountyContract.feesCollected();
  
    // Step 3: Call the withdrawFees function
    await bountyContract.withdrawFees({from: owner});
  
    // Step 4: Get the updated balance of the contract
    const updatedBalance = await web3.eth.getBalance(bountyContract.address);
  
    // Step 5: Check if the balance of the contract has decreased by the amount of fees collected
    expect(initialBalance - updatedBalance).to.equal(feesCollected);
  });
// Test the reset of fees collected by the contract
it("should allow the contract owner to reset the collected fees", async () => {
  // Get the current balance of the contract
  const initialBalance = await web3.eth.getBalance(bountyInstance.address);

  // Add some fees to the contract
  await bountyInstance.methods.requestToAcceptBounty(0, {
    from: requester,
    value: web3.utils.toWei("1", "ether"),
  });

  // Get the current balance of the contract
  const balanceAfterAddingFees = await web3.eth.getBalance(bountyInstance.address);

  // Ensure that the contract's balance has increased
  expect(balanceAfterAddingFees).to.be.gt(initialBalance);

  // Reset the collected fees
  await bountyInstance.methods.resetCollectedFees().send({ from: owner });

  // Get the current balance of the contract
  const balanceAfterReset = await web3.eth.getBalance(bountyInstance.address);

  // Ensure that the contract's balance has been reset to its original value
  expect(balanceAfterReset).to.be.eq(initialBalance);
});
