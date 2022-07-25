const { run, network, deployments, getNamedAccounts, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = network.config.chainId;
    const VRF_FUND_AMOUNT = ethers.utils.parseEther("30");
    let vrfCoordinatorV2Addr, subscriptionId

    if (developmentChains.includes(network.name)) {
        // dev env
        const VRFCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Addr = VRFCoordinatorV2Mock.address;
        const transactionResp = await VRFCoordinatorV2Mock.createSubscription();
        const transactionReceipt = await transactionResp.wait(1);
        subscriptionId = transactionReceipt.events[0].args.subId;

        await VRFCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_FUND_AMOUNT);


    } else {
        vrfCoordinatorV2Addr = networkConfig[chainId]["vrfCoordinatorV2"];
        subscriptionId = networkConfig[chainId]["subscriptionId"];
    }

    // address vrfCoordinator,
    // uint256 entranceFee,
    // bytes32 keyHash,
    // uint64 subscriptionId,
    // uint32 callbackGasLimit,
    // uint256 interval
    const _args = [
        vrfCoordinatorV2Addr,
        networkConfig[chainId]["entranceFee"],
        networkConfig[chainId]["keyHash"],
        subscriptionId,
        networkConfig[chainId]["callbackGasLimit"],
        networkConfig[chainId]["interval"],
    ];

    const raffle = await deploy("Raffle", {
        from: deployer,
        args: _args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log("raffle deployed...")


    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("verifying...")
        await verify(raffle.address, _args)
    }

    log("end...")


}

module.exports.tags = ["all", "raffle"]