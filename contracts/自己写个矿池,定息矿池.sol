 // SPDX-License-Identifier: MIT  

pragma solidity ^0.8.7;  
 
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

contract StakeContract {
    // uint public stakeTime;
    uint public ratio;
    address public staketoken;
    address public totoken;
    uint public stakeSupple;
    address public owner;
    
    event Trasfer(address indexed from, address indexed to, uint amout);
    event Approveal(address indexed owner, address indexed spender, uint amout);
    event transfer(address indexed to, uint amout);

    struct User {
        uint stakeNumber;
        uint last_Stake_Time;
        uint last_totoken_ratio;
        uint whole_ratio;
        uint last_totoken_Time;
    }

    mapping(address => User) public User_Map;

    constructor (address _staketoken, address _totoken) {
        owner = msg.sender;
        require(_staketoken != address(0),"NOT,S 0X ADDRESS");
        require(_totoken != address(0),"NOT,S 0X ADDRESS");
        require(_staketoken == _totoken,"NEED agreement");
        staketoken = _staketoken;
        totoken = _totoken;
    }

    modifier onlyOwner() {
        require(msg.sender == owner , "not owner");
        _;
    }

    // function getStakeTime() public view returns (uint) {
    //     return stakeTime;
    // }

    function setRatio(uint _ratio) external onlyOwner {    
        ratio = _ratio;     
    }

    function Stake(uint _amount) public returns (bool){

        IERC20(staketoken).transferFrom(msg.sender, address(this), _amount); 

        emit Trasfer(msg.sender, address(this), _amount);

        User_Map[msg.sender].last_totoken_ratio = (block.timestamp - User_Map[msg.sender].last_Stake_Time) * ((User_Map[msg.sender].stakeNumber * ratio /100) / 31536000)  ;
        User_Map[msg.sender].stakeNumber += _amount;
        User_Map[msg.sender].last_Stake_Time = block.timestamp;
        stakeSupple += _amount;
        User_Map[msg.sender].last_totoken_Time = User_Map[msg.sender].last_Stake_Time;
        return true;  

    }

    function withDraw () public returns (bool) {
        IERC20(staketoken).transfer(msg.sender, User_Map[msg.sender].stakeNumber); 

        emit transfer(msg.sender, User_Map[msg.sender].stakeNumber);
            
        stakeSupple -= User_Map[msg.sender].stakeNumber;
        User_Map[msg.sender].stakeNumber = 0;

        return true;
    }

    function harvest() public returns (bool) {
        User_Map[msg.sender].whole_ratio = User_Map[msg.sender].last_totoken_ratio + (block.timestamp - User_Map[msg.sender].last_Stake_Time) * ((User_Map[msg.sender].stakeNumber * ratio /100) / 31536000);
        IERC20(totoken).transfer(msg.sender, User_Map[msg.sender].whole_ratio); 

        emit transfer(msg.sender, User_Map[msg.sender].whole_ratio);

        User_Map[msg.sender].whole_ratio = 0;
        User_Map[msg.sender].last_totoken_ratio = 0;
        User_Map[msg.sender].last_totoken_Time = block.timestamp;
        return true;
    }
    
    // function withDrawtwo (uint _amount) public returns (bool) {
    //     require(_amount <= User_Map[msg.sender].stakeNumber, "buzu");
    //     IERC20(staketoken).transfer(msg.sender, _amount); 
    //     User_Map[msg.sender].stakeNumber -= _amount;
    //     stakeSupple -= _amount;
    //     return true;
    // }


    function newTotokenRatio() public view returns (uint) {
        uint newtime = block.timestamp - User_Map[msg.sender].last_totoken_Time;
        uint newTotokenRatione = newtime * ((User_Map[msg.sender].stakeNumber * ratio /100) / 31536000);
        return newTotokenRatione;  
    }

    function lastTotokenRatio()public view returns(uint) {
        uint _lastTotokenRatio = User_Map[msg.sender].last_totoken_ratio;
        return _lastTotokenRatio;
    }


    // function harvestwithDraw() public returns (bool) {
    //     User_Map[msg.sender].whole_ratio = User_Map[msg.sender].last_totoken_ratio + (block.timestamp - User_Map[msg.sender].last_Stake_Time) * ((User_Map[msg.sender].stakeNumber * ratio /100) / 31536000);
    //     IERC20(totoken).transfer(msg.sender, User_Map[msg.sender].whole_ratio); 

    //     emit transfer(msg.sender, User_Map[msg.sender].whole_ratio);

    //     User_Map[msg.sender].whole_ratio = 0;
    //     User_Map[msg.sender].last_totoken_ratio = 0;

    //     IERC20(staketoken).transfer(msg.sender, User_Map[msg.sender].stakeNumber); 

    //     emit transfer(msg.sender, User_Map[msg.sender].stakeNumber);

    //     User_Map[msg.sender].stakeNumber = 0;
    //     stakeSupple -= User_Map[msg.sender].stakeNumber;
    //     return true;
    // }
}
