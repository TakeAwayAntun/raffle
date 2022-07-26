const { assert, expect } = require("chai")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

// !developmentChains.includes(network.name)
//     ? describe.skip
//     : 

describe("Raffle Unit Tests", function () {
    let raffle, vrfCoordinator, deployer, raffleEntranceFee
    const chainId = network.config.chainId

    beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer
        await deployments.fixture(["all"]);
        raffle = await ethers.getContract("Raffle", deployer);
        vrfCoordinator = await ethers.getContract("VRFCoordinatorV2Mock", deployer);
        raffleEntranceFee = await raffle.getEntranceFee()
    })

    describe("constructor", function () {
        it("Initializes the raffle correctly.", async function () {
            const state = await raffle.getRaffleState();
            const interval = await raffle.getInterval();
            assert.equal(state.toString(), "0");
            assert.equal(interval.toString(), networkConfig[chainId]["interval"]);
        })

    })

    describe("play", function () {
        it("not enough eth", async function () {
            await expect(raffle.enterRaffle()).to.revertedWith("Not_Enough_ETH_Entered")
        })

        it("show player when somebody enter", async () => {
            await raffle.enterRaffle({ value: raffleEntranceFee })
            const player = await raffle.getPlayers(0)
            assert.equal(player, deployer)
        })

        it("emit event", async () => {
            await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.emit(
                raffle,
                "RaffleEnter"
            )

        })
    })



})