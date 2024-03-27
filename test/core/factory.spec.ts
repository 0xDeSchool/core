import { assert, expect } from "chai";
import { deployer, hubManager } from "../setup.spec";
import { ZeroAddress } from "ethers";
import { AssetHubManager__factory, AssetHub__factory } from "../../typechain-types";
import { ethers } from "hardhat";

const HUB_NAME = "TEST_HUB"

describe("AssetHubFactory", async function () {
  it("should deploy a new assethub", async function () {
    const args = {
      admin: await deployer.getAddress(),
      name: HUB_NAME,
      collectNft: true,
      assetCreateModule: ZeroAddress,
    }
    await expect(hubManager.deploy(args)).to.not.be.reverted;
  });

  it("should not deploy a existed name hub", async function () {
    await expect(hubManager.deploy({
      admin: await deployer.getAddress(),
      name: HUB_NAME,
      collectNft: true,
      assetCreateModule: ZeroAddress,
    })).to.be.revertedWithCustomError(hubManager, "NameHubExisted")
      .withArgs(HUB_NAME);
  })

  it("should deploy a new name hub", async function () {
    await expect(hubManager.deploy({
      admin: await deployer.getAddress(),
      name: HUB_NAME + "_V2",
      collectNft: true,
      assetCreateModule: ZeroAddress,
    })).to.not.be.reverted;
  })

  it("collect moudule should be whitelishted in hub", async function () {
    const tx = await hubManager.deploy({
      admin: await deployer.getAddress(),
      name: HUB_NAME + "_V3",
      collectNft: true,
      assetCreateModule: ZeroAddress,
    })
    const resp = await tx.wait();
    expect(resp?.logs).to.not.be.empty;
    const logdata = resp!.logs.find((log) => log.topics[0] === hubManager.interface.getEvent("AssetHubDeployed").topicHash);
    expect(logdata).to.not.be.undefined;
    const logRes = AssetHubManager__factory.createInterface().decodeEventLog("AssetHubDeployed", logdata!.data, logdata!.topics);
    const hubAddr = logRes[2];
    const tokenCollectModule = logRes[3][3];
    const feeCollectModule = logRes[3][4];
    const hub = AssetHub__factory.connect(hubAddr, deployer);
    expect(await hub.isCollectModuleWhitelisted(tokenCollectModule)).to.be.true;
    expect(await hub.isCollectModuleWhitelisted(feeCollectModule)).to.be.true;
  });
});