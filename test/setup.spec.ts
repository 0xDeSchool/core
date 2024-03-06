import { ethers, upgrades } from 'hardhat';
import "@openzeppelin/hardhat-upgrades";
import { AssetHub, AssetHub__factory, AssetHubFactory__factory, AssetHubLogic, AssetHubLogic__factory, AssetHubManager, AssetHubManager__factory, CollectNFT, CollectNFT__factory, Events, Events__factory, FeeCollectModuleFactory__factory, FeeCreateAssetModuleFactory__factory, NftAssetGatedModuleFactory__factory, TestERC1155, TestERC1155__factory, TestERC721, TestERC721__factory, TestToken, TestToken__factory, TokenTransfer__factory, UUPSUpgradeable, UUPSUpgradeable__factory } from "../typechain-types";
import { Contract, ContractFactory, Signer, ZeroAddress } from 'ethers';
import { expect } from 'chai';
import { AssetHubLibraryAddresses } from '../typechain-types/factories/contracts/core/AssetHub__factory';

export let accounts: Signer[];
export let deployer: Signer;
export let user: Signer;
export let user3: Signer;
export let userAddress: string;
export let deployerAddress: string;
export let testToken: TestToken;
export let testErc721: TestERC721;
export let testErc1155: TestERC1155;
export let assethubLibs: AssetHubLibraryAddresses;
export let eventsLib: Events;
export let hubManager: AssetHubManager;

export type DeployCtx = {
  assetHub: AssetHub
  tokenImpl: TestToken
}

export async function deployContracts(): Promise<DeployCtx> {
  const tokenImpl = await new TestToken__factory(deployer).deploy("EmptyToken", "ET")
  const hubAddress = await hubManager.deploy.staticCall({
    name: "TestHUb",
    admin: deployerAddress,
    collectNft: true
  })
  await expect(hubManager.deploy({
    name: "TestHUb",
    admin: deployerAddress,
    collectNft: true
  })).to.not.be.reverted;
  const assetHub = await ethers.getContractAt("AssetHub", hubAddress, deployer)
  return {
    assetHub,
    tokenImpl,
  }
}

before(async function () {
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  user = accounts[1];
  user3 = accounts[2];
  deployerAddress = await deployer.getAddress()
  userAddress = await user.getAddress()

  it("user address", async function () {
    expect(user).to.not.be.undefined
  })

  testErc721 = await new TestERC721__factory(deployer).deploy("TEST721", "T721")
  testErc1155 = await new TestERC1155__factory(deployer).deploy()
  testToken = await new TestToken__factory(deployer).deploy("TEST", "TST")
  const libAsset = await new AssetHubLogic__factory(deployer).deploy()
  assethubLibs = {
    "contracts/base/AssetHubLogic.sol:AssetHubLogic": await libAsset.getAddress()
  }
  // Event library deployment is only needed for testing and is not reproduced in the live environment
  eventsLib = await new Events__factory(deployer).deploy();

  const assetHubFactory = await new AssetHubFactory__factory(assethubLibs, deployer).deploy();
  const feeCollectModuleFactory = await new FeeCollectModuleFactory__factory(deployer).deploy();
  const nftGatedModuleFactory = await new NftAssetGatedModuleFactory__factory(deployer).deploy();
  const FeeAssetCreateModule = await new FeeCreateAssetModuleFactory__factory(deployer).deploy();
  const factory = new AssetHubManager__factory(deployer);
  const hubManagerProxy = await upgrades.deployProxy(factory, [], {
    kind: "uups",
    initializer: false,
    unsafeAllow: ["external-library-linking"],
  })
  hubManager = await ethers.getContractAt("AssetHubManager", hubManagerProxy);
  await expect(hubManager.initialize({
    assetHubFactory: await assetHubFactory.getAddress(),
    feeCollectModuleFactory: await feeCollectModuleFactory.getAddress(),
    nftGatedModuleFactory: await nftGatedModuleFactory.getAddress(),
    feeCreateAssetModuleFactory: await FeeAssetCreateModule.getAddress()
  })).to.not.be.reverted;
});


