const { run, network, deployments, getNamedAccounts, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

const baseFee = ethers.utils.parseEther("0.25");
const gasPriceLink = 1e9;

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    log("--->"+ deployer)
    if (developmentChains.includes(network.name)) {
        log("local network, deploying mocks...");
        const _args = [baseFee, gasPriceLink];

        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: _args
        });
        log("--------------mocks deployed------------");
    }

}

module.exports.tags = ["all", "mocks"]