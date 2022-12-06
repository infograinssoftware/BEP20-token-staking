contract Staking is Context, Ownable, GROToken {
    using SafeMath for uint256;

    address[] internal stakeholders;

    GROToken public GRO;

    struct stakeHolder {
        uint256 amount;
        uint256 stakeTime;
    }
    uint256 public tokenPrice = 10000000000000; //1.0;

    uint256 public APY = 1000; // 10.0%

    mapping(address => stakeHolder) public stakes;

    mapping(address => uint256) internal rewards;

    uint256 public totalTokenStaked;

    constructor(GROToken _address) public payable {
        GRO = _address;
    }

    //create stake
    function createStake(uint256 _numberOfTokens) public payable returns (bool)
    {
        require(
            msg.value == _numberOfTokens.mul(tokenPrice),
            "Price value mismatch"
        );
        require(
            GRO.totalSupply() >=(_numberOfTokens.mul(GRO.decimalFactor().add(totalTokenStaked))),
            "addition error"
        );
        require(
            _mint(_msgSender(), _numberOfTokens.mul(GRO.decimalFactor())),
            "mint error"
        );
        stakeholders.push(_msgSender());
        totalTokenStaked = totalTokenStaked.add(
        _numberOfTokens.mul(GRO.decimalFactor())
        );
        uint256 previousStaked = stakes[_msgSender()].amount;
        uint256 finalStaked = previousStaked.add(msg.value);
        stakes[_msgSender()] = stakeHolder(finalStaked, block.timestamp);
        return true;

        
    }

    //remove stake
    function removeStake(uint256 _numberOfTokens)
        public
        payable
        returns (bool)
    {
        // require(
        //     (stakes[_msgSender()].stakeTime + 7 seconds) <= block.timestamp,
        //     "You have to stake for minimum 7 seconds."
        // );

        require(
            (stakes[_msgSender()].stakeTime + 180 days) <= block.timestamp,
            "You have to stake for minimum 6 months."
        );

        require(
            stakes[_msgSender()].amount == _numberOfTokens.mul(tokenPrice),
            "You have to unstake all your tokens"
        );
        uint256 stake = stakes[_msgSender()].amount;

        //calculate reward
        uint256 rew = calculateReward(_msgSender());
        uint256 totalAmount = stake.add(rew);
        _msgSender().transfer(totalAmount);
        totalTokenStaked = totalTokenStaked.sub(
            _numberOfTokens.mul(GRO.decimalFactor())
        );
        stakes[_msgSender()] = stakeHolder(0, 0);
        removeStakeholder(_msgSender());
        _burn(_msgSender(), _numberOfTokens.mul(GRO.decimalFactor()));
        return true;
    }

    //get stake
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakes[_stakeholder].amount;
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    //reward of
    function rewardOf(address _stakeholder) public view returns (uint256) {
        return rewards[_stakeholder];
    }

    // calculate stake
    function calculateReward(address _stakeholder)
        public
        view
        returns (uint256)
    {
        uint256 reward;
        if ((stakes[_stakeholder].stakeTime + 7 seconds) <= block.timestamp) {
            reward = ((stakes[_stakeholder].amount).mul(APY)).div(
                uint256(10000)
            );
        } else {
            reward = 0;
        }
        return reward;
    }

    function viewReward(address _stakeholder) public view returns (uint256) {
        uint256 reward;

        reward = ((stakes[_stakeholder].amount).mul(APY)).div(uint256(10000));
        return reward;
    }

    // distribute rewards
    function distributeRewards() public onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    //   withdraw rewards
    function withdrawReward() public {
        uint256 reward = calculateReward(_msgSender());
        rewards[msg.sender] = 0;
        _msgSender().transfer(reward);
    }
}
