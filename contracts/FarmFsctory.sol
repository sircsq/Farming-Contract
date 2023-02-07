// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


import "./interfaces/ISoonFarming.sol";
import {TransferLib} from './libraries/TransferLib.sol';

import "./SoonFarming.sol";
import "./Allowlisted.sol";

contract FarmFsctory is Allowlisted,Ownable,AccessControl,Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CUT_SHORT_ROLE = keccak256("CUT_SHORT_ROLE");
    bytes32 public constant BLOCK_ROLE = keccak256("BLOCK_ROLE");


    address public farmAdmin;

    mapping(address => address[]) public getFarm;
    address[] public allFarm;

    event createFarmEvent(
            address farm,
            string  name,
            address stakeTokenAddr,
            uint   rewardTokenNumber,
            address rewardToken1Addr,
            address rewardToken2Addr,
            uint256 reward1,
            uint256 reward2,
            uint256 beginTime,
            uint256 endTime
        );

        constructor(address _farmAdmin )  {
            farmAdmin = _farmAdmin;
            _setupRole(DEFAULT_ADMIN_ROLE, _farmAdmin);
        }


    function setupRole(bytes32 _role,address account) public  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "FarmFsctory:permission denied !");
        _setupRole(_role, account);
    }

    function farmHasRole(bytes32 _role,address account) public view returns (bool){
        return hasRole(_role, account);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function blockAccount(address[] memory accounts) external onlyOwner {
        require(hasRole(BLOCK_ROLE,_msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonFarming:permission denied !");
        for (uint i = 0; i < accounts.length; i++) {
                _blockAddress(accounts[i]);
            }
        }

    function unblockAccount(address[] memory accounts) external onlyOwner {
        require(hasRole(BLOCK_ROLE,_msgSender()) ||
            hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonFarming:permission denied !");
        for (uint i = 0; i < accounts.length; i++) {
            _unblockAddress(accounts[i]);
        }
    }

    function isAccountBlocked(address account) external view returns (bool){
        return IsAccountBlocked(account);
    }

    function allFarmLength() external view returns (uint) {
        return allFarm.length;
    }

    // 设置管理员
    function setFarmAdmin(address _farmAdmin)  public onlyOwner {
        farmAdmin = _farmAdmin;
    }

    function getFarmAdmin() external view returns (address ){
        return farmAdmin;
    }

    function getFarms(address lpToken) external view returns (address[] memory farms){
        return  getFarm[lpToken];
    }


    function createFarm(
        string memory _name,
        address _stakeTokenAddr,
        uint    _rewardTokenNumber,
        address _rewardToken1Addr,
        address _rewardToken2Addr,
        uint256 _reward1,
        uint256 _reward2,
        uint256 _beginTime,
        uint256 _endTime
    ) external returns (address farm) {
        require(hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "SoonswapFactory:Only administrators have create Farm privileges");
        require(!paused(), "SoonswapFactory: createFarm suspended due to paused");
        uint timestamp = block.timestamp;
        bytes32 _salt = keccak256(abi.encodePacked(_name, _beginTime,_endTime,timestamp));
        farm =  address(new SoonFarming{salt: bytes32(_salt)}());
        ISoonFarming(farm).initialize(
                                        _name,
                                        _stakeTokenAddr,
                                        _rewardTokenNumber,
                                        _rewardToken1Addr,
                                        _rewardToken2Addr,
                                        _reward1 ,
                                        _reward2 ,
                                        _beginTime,
                                        _endTime
                                    );
        uint256 balance = IERC20(_rewardToken1Addr).balanceOf(msg.sender);
        require(balance >= _reward1, 'FarmFactory: balance < _reward1');
        IERC20(_rewardToken1Addr).transferFrom(msg.sender, address(this), _reward1);
        TransferLib.approve(_rewardToken1Addr, farm, _reward1);
        TransferLib.safeTransfer(_rewardToken1Addr, farm, _reward1);
        if(_rewardTokenNumber > 1 ){
            uint256 balance2 = IERC20(_rewardToken2Addr).balanceOf(msg.sender);
            require(balance2 >= _reward2, 'FarmFactory: balance2 < _reward2');
            IERC20(_rewardToken2Addr).transferFrom(msg.sender, address(this), _reward2);
            TransferLib.approve(_rewardToken2Addr, farm, _reward2);
            TransferLib.safeTransfer(_rewardToken2Addr, farm, _reward2);
        }
        getFarm[_stakeTokenAddr].push(farm);
        allFarm.push(farm);
        emit createFarmEvent(
                    farm,
                    _name,
                    _stakeTokenAddr,
                    _rewardTokenNumber,
                    _rewardToken1Addr,
                    _rewardToken2Addr,
                    _reward1,
                    _reward2,
                    _beginTime,
                    _endTime
            );
    }

}
