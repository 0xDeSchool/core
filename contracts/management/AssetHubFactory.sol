// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1967Proxy} from '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';
import {IAssetHubFactory, IUUPSUpgradeable} from './IFactory.sol';
import {AssetHub} from '../core/AssetHub.sol';

contract AssetHubFactory is IAssetHubFactory {
    function create(bytes calldata /*initData*/) external returns (address) {
        AssetHub assetHubImpl = new AssetHub();
        ERC1967Proxy proxy = new ERC1967Proxy(address(assetHubImpl), '');
        return address(proxy);
    }
}
