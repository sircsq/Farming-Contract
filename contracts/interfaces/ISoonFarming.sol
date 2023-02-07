// SPDX-License-Identifier: AGPL-3.0
pragma solidity = 0.8.17;




interface ISoonFarming {

    event StakeEvent(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );

    event UnStakeEvent(
        address indexed sender,
        uint256 unStakeAmount,
        uint256 reward1,
        uint256 reward2,
        uint256 timestamp
    );

    event ClaimEvent(
        address indexed sender,
        uint256 reward1,
        uint256 reward2,
        uint256 timestamp
    );

    event WithdrawEvent(
        address token,
        address account,
        uint256 amount
    );

    event CutShortEvent(
        address sender,
        uint256 aheadTime,
        uint256 timestamp
    );

    function initialize(
        string memory name_,
        address _stakeTokenAddr,
        uint _rewardTokenNumber,
        address _rewardToken1Addr,
        address _rewardToken2Addr,
        uint256 _rewardPerMin1,
        uint256 _rewardPerMin2,
        uint256 _beginTime,
        uint256 _endTime
    ) external;

    function name() external view returns (string memory);
    function getReward(address account) external view returns (uint256 reward1, uint256 reward2);
    function getTotalStake() external view returns (uint256 totalStake);
    function getUserStake(address account) external view returns (uint256 userStake);
    function getaAtivityTime() external view returns (uint256 beginTime, uint256 endTime);


    function stake(uint256 amount) external;
    function unStake( uint256 amount) external returns (uint256,uint256);
    function claim() external returns (uint256 , uint256 );


}
