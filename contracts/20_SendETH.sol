// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
error CallFailed(); // 用call发送ETH失败error
contract SendETH {


    constructor() payable {}
    receive() external payable {}

    function transferETH(address payable _to, uint256 amount) external payable {
        _to.transfer(amount);
    }

    function callETH(address payable _to, uint256 amount) external payable {
        (bool success,) = _to.call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
    }
}