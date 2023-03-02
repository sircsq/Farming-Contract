const ERC20MockContract = artifacts.require("./mock/ERC20MockContract.sol");
const FarmFsctory = artifacts.require("FarmFsctory");
const SoonFarming = artifacts.require("SoonFarming");

const web3 = require("web3")
const BN = web3.utils.BN;

const toWei = (number) => {
    return web3.utils.toWei(BN(number));
}

let FarmAdmin = "0x0F7cBa1C8d8eD2d1D450bABD4A66f803de7b9E0C" ;
let FarmAdmin2 = "0x9036Cc15a5B190159d6deE6af586C0353BCB1Bb9" ;
let admin_role = "0x0000000000000000000000000000000000000000000000000000000000000000" ;

module.exports = async function (deployer,network, accounts) {

    await deployer.deploy(FarmFsctory, accounts[0]);
    const farmFsctory = await FarmFsctory.deployed();
    await farmFsctory.setFarmAdmin(FarmAdmin);
    await farmFsctory.setFarmAdmin(FarmAdmin2);
    await farmFsctory.grantRole(FarmAdmin,admin_role);
    await farmFsctory.grantRole(FarmAdmin2,admin_role);
    console.log("farmFsctory:",farmFsctory.address)
};



