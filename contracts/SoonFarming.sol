// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./FarmFsctory.sol";
import "./interfaces/ISoonFarming.sol";
import "./libraries/TransferLib.sol";

contract SoonFarming is ISoonFarming,AccessControl,Pausable,Ownable {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CUT_SHORT_ROLE = keccak256("CUT_SHORT_ROLE");
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");
    uint  private blockTime  = 15;  //15s

    string private _name;

    address public factory;

    address stakeToken;

    uint rewardTokenNumber;

    IERC20 rewardToken1;
    IERC20 rewardToken2;

    uint256 rewardPerMin1;
    uint256 rewardPerMin2;

    uint256 totalReward1;
    uint256 totalReward2;

    uint256 beginTime;
    uint256 endTime;
    uint256 aheadTime;

    uint256 public totalStake;

    mapping(address => uint256) public userSake;

    mapping(address => uint256) public withdrawdReward1;
    mapping(address => uint256) public withdrawdReward2;

    FarmStake[] public timeStake;
    mapping(address => FarmStake[]) public userTimeStake;

    struct FarmStake{
        uint256 time;
        uint256 amount;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'SoonFarming: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(){
        factory = msg.sender;
    }


    function initialize(
        string memory name_,
        address _stakeTokenAddr,
        uint _rewardTokenNumber,
        address _rewardToken1Addr,
        address _rewardToken2Addr,
        uint256 _reward1,
        uint256 _reward2,
        uint256 _beginTime,
        uint256 _endTime
    ) external {
        require(msg.sender == factory, 'SoonFarming: FORBIDDEN');
              _name =  name_;
        stakeToken = _stakeTokenAddr;
        rewardTokenNumber = _rewardTokenNumber;
        rewardToken1 = IERC20(_rewardToken1Addr);
        rewardToken2 = IERC20(_rewardToken2Addr);
        totalReward1 = _reward1;
        totalReward2 = _reward2;
        beginTime = _beginTime;
        endTime = _endTime;
        uint256 time = _endTime - _beginTime;
        rewardPerMin1 = _reward1 / (time/blockTime);
        rewardPerMin2 = _reward2 / (time/blockTime);
    }


    function pause() public  {
        require(_farmHasRole(PAUSER_ROLE,_msgSender()) ||
            _farmHasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonFarming:permission denied !");
        _pause();
    }

    function unpause() public  {
        require(_farmHasRole(PAUSER_ROLE,_msgSender()) ||
            _farmHasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonFarming:permission denied !");
        _unpause();
    }

    function cutShort(uint256 _aheadTime) public  {
        require(_farmHasRole(CUT_SHORT_ROLE,_msgSender()) ||
                 _farmHasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonFarming:permission denied !");
        require(!paused(), "SoonFarming: stake suspended due to paused");
        require(block.timestamp >= endTime, "SoonFarming: block.timestamp >= endTime");
        require(block.timestamp <= _aheadTime, "SoonFarming: block.timestamp <= _aheadTime");
        require(_aheadTime > beginTime && _aheadTime <= endTime, "SoonFarming: The time range is wrong");
        aheadTime = _aheadTime;
        emit StakeEvent(msg.sender,_aheadTime,block.timestamp);
    }


  function test() public view virtual  returns (uint256 ) {
      uint256 a = 2;
       uint256 b = 1;
        return (b-a);
    }

    function name() public view virtual  returns (string memory) {
        return _name;
    }

    function getFarmStakeSize() external view returns (uint256 ){
        return timeStake.length;
    }

    function getReward(address _account) external view returns (uint256 , uint256 ){
        uint256  _reward1 = 0;
        uint256  _reward2 = 0;
        FarmStake[] memory _userTimeStakes = userTimeStake[_account];
        for (uint i = 0; i < _userTimeStakes.length; i++) {
            FarmStake memory _timeStake =   _userTimeStakes[i];
            uint256  _userTime =  _timeStake.time;
            uint256  _userAmount =  _timeStake.amount;
            uint256 _farmAount =  _getTimeStake(_userTime);
            if(_userTimeStakes.length > (i + 1)){
                FarmStake memory _userStakeLatter  =   _userTimeStakes[i+1];
                uint256  _userTimeLatter =  _userStakeLatter.time;
                uint256  _totalReward1 = rewardPerMin1 * (_userTimeLatter - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (_userTimeLatter - _userTime) / blockTime;
                if(_farmAount > 0){
                    _reward1 += (_totalReward1 * _userAmount / _farmAount);
                    _reward2 += (_totalReward2 * _userAmount / _farmAount);
                }
            }else if(block.timestamp <= endTime && aheadTime == 0){
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (block.timestamp - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (block.timestamp - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }else if(aheadTime > 0 ){
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (aheadTime - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (aheadTime - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }else {
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (endTime - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (endTime - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }
        }
        if(_reward1 >= withdrawdReward1[_account]){
            _reward1 -= withdrawdReward1[_account];
        }
        if(_reward2 >= withdrawdReward2[_account]){
            _reward2 -= withdrawdReward2[_account];
        }
        return(_reward1,_reward2);
    }

    function getTotalStake() external view returns (uint256 ){
        return totalStake;
    }

    function getUserStake(address account) external view returns (uint256 userStake){
        return userSake[account];
    }

    function getaAtivityTime() external view returns (uint256 , uint256 ){
        return (beginTime,endTime);
    }

    function stake(uint256 _amount)public virtual lock {
        require(!_farmBlocked(_msgSender()), "SoonFarming:They are blacklisted users");
        require(!paused(), "SoonFarming: stake suspended due to paused");
        require(beginTime <= block.timestamp && block.timestamp <= endTime, "SoonFarming: Not within the stake time");
        uint256 lpBalance = IERC20(stakeToken).balanceOf(msg.sender);
        require(lpBalance >= _amount, "SoonFarming:LpBalance not sufficient funds");
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount);
        totalStake += _amount;
        userSake[msg.sender] +=  _amount;
        FarmStake memory farmStake  = FarmStake(block.timestamp,totalStake);
        timeStake.push(farmStake);
        FarmStake memory _userFarmStake  = FarmStake(block.timestamp,userSake[msg.sender]);
        userTimeStake[msg.sender].push(_userFarmStake);
        emit StakeEvent(msg.sender,_amount,block.timestamp);
    }

    function unStake(uint256 _amount)  public virtual lock returns(uint256,uint256){
        require(!_farmBlocked(_msgSender()), "SoonFarming:They are blacklisted users");
        require(!paused(), "SoonFarming: stake suspended due to paused");
        require(beginTime <= block.timestamp, "SoonFarming:The release of the pledge must be after the opening");
        require(userSake[_msgSender()] >= _amount, "SoonFarming:userSake >= unStake");
        require(_amount > 0, "SoonFarming:_amount > 0");
        (uint256 _reward1,uint256 _reward2) = _reward(_msgSender());
        withdrawdReward1[msg.sender] += _reward1;
        withdrawdReward2[msg.sender] += _reward2;
        userSake[msg.sender] =  (userSake[msg.sender] - _amount);
        totalStake  -= _amount;
        FarmStake memory _farmStake  = FarmStake(block.timestamp,totalStake);
        timeStake.push(_farmStake);
        FarmStake memory _userStake  = FarmStake(block.timestamp,userSake[msg.sender]);
        userTimeStake[msg.sender].push(_userStake);
        TransferLib.safeTransfer(stakeToken, msg.sender, _amount);
        if(_reward1 > 0 ){
            TransferLib.safeTransfer(address(rewardToken1), msg.sender, _reward1);
        }
        if(_reward2 > 0 ){
            TransferLib.safeTransfer(address(rewardToken2), msg.sender, _reward2);
        }
        emit UnStakeEvent(msg.sender,_amount,_reward1,_reward2,block.timestamp);
        return (_reward1, _reward2);
    }


    function claim() public virtual lock returns(uint256 , uint256 ){
        require(!_farmBlocked(_msgSender()), "SoonFarming:They are blacklisted users");
        require(!paused(), "SoonFarming: stake suspended due to paused");
        (uint256 _reward1,uint256 _reward2) = _reward(_msgSender());
        if(_reward1 == 0 && _reward2 == 0){
            return (0,0);
        }
        withdrawdReward1[msg.sender] += _reward1;
        withdrawdReward2[msg.sender] += _reward2;
        if(_reward1 > 0 ){
            TransferLib.safeTransfer(address(rewardToken1), msg.sender, _reward1);
        }
        if(_reward2 > 0 ){
            TransferLib.safeTransfer(address(rewardToken2), msg.sender, _reward2);
        }
        emit ClaimEvent(msg.sender,_reward1,_reward2,block.timestamp);
        return (_reward1, _reward2);
    }

    function withdraw(address token, address account,uint256 amount) public payable lock {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SoonFarming:permission denied !");
        TransferLib.safeTransfer(token, account, amount);
        emit WithdrawEvent(token,account,amount);
    }

    function _farmBlocked(address account) private view returns (bool){
        return FarmFsctory(factory).isAccountBlocked(account);
    }

    function _farmHasRole(bytes32 _role,address account) private view returns (bool){
        return FarmFsctory(factory).farmHasRole(_role, account);
    }

    function _reward(address _account) private view returns (uint256 , uint256 ){
        uint256  _reward1 = 0;
        uint256  _reward2 = 0;
        FarmStake[] memory _userTimeStakes = userTimeStake[_account];
        for (uint i = 0; i < _userTimeStakes.length; i++) {
            FarmStake memory _timeStake =   _userTimeStakes[i];
            uint256  _userTime =  _timeStake.time;
            uint256  _userAmount =  _timeStake.amount;
            uint256 _farmAount =  _getTimeStake(_userTime);
            if(_userTimeStakes.length > (i + 1)){
                FarmStake memory _userStakeLatter  =   _userTimeStakes[i+1];
                uint256  _userTimeLatter =  _userStakeLatter.time;
                uint256  _totalReward1 = rewardPerMin1 * (_userTimeLatter - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (_userTimeLatter - _userTime) / blockTime;
                if(_farmAount > 0){
                    _reward1 += (_totalReward1 * _userAmount / _farmAount);
                    _reward2 += (_totalReward2 * _userAmount / _farmAount);
                }
            }else if(block.timestamp <= endTime && aheadTime == 0){
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (block.timestamp - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (block.timestamp - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }else if(aheadTime > 0 ){
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (aheadTime - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (aheadTime - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }else {
                uint256  _userSake = userSake[_account];
                uint256  _totalReward1 = rewardPerMin1 * (endTime - _userTime) / blockTime;
                uint256  _totalReward2 = rewardPerMin2 * (endTime - _userTime) / blockTime;
                if(totalStake > 0){
                    _reward1 += (_totalReward1 * _userSake / totalStake);
                    _reward2 += (_totalReward2 * _userSake / totalStake);
                }
            }
        }
        if(_reward1 >= withdrawdReward1[_account]){
            _reward1 -= withdrawdReward1[_account];
        }
        if(_reward2 >= withdrawdReward2[_account]){
            _reward2 -= withdrawdReward2[_account];
        }
        return(_reward1,_reward2);
    }

    function _getTimeStake(uint256 _time) private view returns (uint256 ){
        for (uint i = 0; i < timeStake.length; i++) {
            FarmStake  memory _farmStake =   timeStake[i];
            if(_farmStake.time == _time){
                return _farmStake.amount;
            }
        }
        return 0;
    }
}
