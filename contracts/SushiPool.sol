// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract SushiPool {

    struct User {
        uint256 stakeNumber;
        uint256 stakeTime;
        uint256 insert;
        uint256 ru;
    }

    mapping(address => User) public users;

    // 总质押量
    uint256 public stakeTotal;
    // 每秒产出
    uint256 public output;
    // 每秒每个代币产出收益
    uint256 public rn;
    // 用户上次质押时间
    uint256 public lastStakeTime;
    // 开始时间
    uint256 public startAt;
    // 当前时间
    uint256 public currentAt;

    constructor(uint256 _output) {
        output = _output;
    }

    /**
     * 用户质押 
     * amount 质押数量
     */
    function stake(uint256 _amount) external {
        User storage user = users[msg.sender];
        uint256 secondOutPut;
        if (stakeTotal != 0) {
            secondOutPut = output / stakeTotal;
        }
        rn += (currentAt - lastStakeTime) * secondOutPut * 10**32;
        user.insert +=  (rn - user.ru) * user.stakeNumber / 10**32;
        user.ru = rn;
        user.stakeNumber += _amount;
        user.stakeTime = currentAt;
        stakeTotal += _amount;
        lastStakeTime = currentAt;
    }

    function getUserInfo() public view returns (uint256 insert, uint256 ru, uint256 stakeNumber) {
        User storage user = users[msg.sender];
        uint256 secondOutPut;
        if (stakeTotal != 0) {
            secondOutPut = output / stakeTotal;
        }
        uint256 _rn = rn + (currentAt - lastStakeTime) * secondOutPut * 10**32;
        insert = user.insert + (_rn - user.ru) * user.stakeNumber / 10**32; 
        ru = user.ru;
        stakeNumber = user.stakeNumber;
    }

    function addAt(uint256 time) external {
        currentAt += time;
    }




    
    
}