// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ReceiveETH {

    event Received(address Sender, uint Value);
    event fallbackCalled(address Sender, uint Value, bytes Data);
    event Log(uint amount, uint gas);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() view public returns(uint) {
        return address(this).balance;
    }
}