// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 100; //+-Amount of Tokens Earned per Second of Staking.
    uint public lastUpdateTime; //+-When was the Last Time that this S.C. was called.
    uint public rewardPerTokenStored; //+-Equals to rewardRate / totalSupplyOfTokensStakedAtThatTime.

    mapping(address => uint) public userRewardPerTokenPaid; //+-rewardPerTokenStored when the User Interacts with the S.C..
    mapping(address => uint) public rewards;/**+-When the User Stakes more Tokens or Withdrawals some Tokens, we will compute
    the Reward of that User and then to store it in this mapping.*/
    
    uint private _totalSupply;//+-Nº of Tokens Staked in this S.C..
    mapping(address => uint) private _balances;+-Nº of Tokens Staked per User.

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account]/**(Current Amount of Tokens Staked by the User).*/ *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account]/**(Current Amount of Rewards that the User Account has Earned).*/;
    }

    //+-Updates the Rewards Calculation every time that the User interacts with the S.C.:_
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }
    
    //+-Users Deposit and Stake Tokens:_
    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    //+-Users withdraw their Staking Tokens:_
    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    //+-Users claim and withdraw their Reward Tokens:_
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
