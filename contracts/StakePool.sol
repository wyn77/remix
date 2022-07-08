// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amout) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amout) external returns (bool);

    function transferFrom(address sender, address recipient, uint amout) external returns (bool);

    event Trasfer(address indexed from, address indexed to, uint amout);
    event Approveal(address indexed owner, address indexed spender, uint amout);

}

contract StakePool{
    event Stake(address indexed user, uint256 stakeNumber);
    event UnStake(address indexed user, uint256 unStakeNumber);
    event Receive(address indexed user, uint256 receiveNumber);
    event UpdateRatio(uint8 ratio);

    struct User {
        uint256 stakeNumber;
        uint256 currentInterest;
        uint256 claimedInterest;
        uint256 lastStakeTime;
    }
    // 默认矿池数量1wei
    uint256 public totalStakeNumber = 1;
    // 代币地址
    address public tokenAddress;
    // 管理员地址
    address public owner;
    uint8 public ratio;
    // 用户质押信息
    mapping(address => User) public userStakes;
    IERC20 public ierc20;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        ierc20 = IERC20(_tokenAddress);
        ratio = 50;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner , "not owner");
        _;
    }

    function setRatio(uint8 _ratio) external onlyOwner {    
        ratio = _ratio;     
        emit UpdateRatio(_ratio);
    }
    
    function stake(uint256 _stakeNumber) external {
        User storage user = userStakes[msg.sender];
        // 计算上次的利息
        user.currentInterest = getUserInsert();
        user.stakeNumber += _stakeNumber;
        user.lastStakeTime = block.timestamp;
        totalStakeNumber += _stakeNumber;

        ierc20.transferFrom(msg.sender, address(this), _stakeNumber);
        emit Stake(msg.sender, _stakeNumber);
    }

    function unStake() external {
        // 取出代币 取出利息
        uint256 insert = getUserInsert();
        User storage user = userStakes[msg.sender];
        uint256 stakeNumber = user.stakeNumber;
        user.claimedInterest += insert;
        user.lastStakeTime = block.timestamp;
        totalStakeNumber -= user.stakeNumber;
        user.stakeNumber = 0;
        user.currentInterest = 0;

        ierc20.transfer(msg.sender, stakeNumber);
        ierc20.transfer(msg.sender, insert);
        emit UnStake(msg.sender, stakeNumber);
        emit Receive(msg.sender, insert);
    }

    function received() external {
        User storage user = userStakes[msg.sender];
        uint256 insert = getUserInsert();
        user.claimedInterest += insert;
        user.lastStakeTime = block.timestamp;
        user.currentInterest = 0;

        ierc20.transfer(msg.sender, insert);
        emit Receive(msg.sender, insert);
    } 

    function getUserInsert() private view returns (uint256 interest) {
        User storage user = userStakes[msg.sender];
        interest = user.currentInterest + 
            (block.timestamp - user.lastStakeTime) * (user.stakeNumber * ratio / 100 / 31536000);
    }

    function getUserInfo(address _userAddress) public view returns (uint256 stakeNumber, uint256 currentInsert, uint256 insert) { 
        User storage user = userStakes[_userAddress];
        stakeNumber = user.stakeNumber;
        currentInsert = getUserInsert();
        insert = user.claimedInterest + currentInsert;
    }
}