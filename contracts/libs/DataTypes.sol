// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library DataTypes {
    enum ProtocolState {
        Normal,
        SubscribingPaused,
        Paused
    }

    struct AssetCreateData {
        address publisher;
        string contentURI;
        bytes assetCreateModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address gatedModule;
        bytes gatedModuleInitData;
    }

    struct AssetUpdateData {
        address collectModule;
        address gatedModule;
    }

    struct Asset {
        string contentURI;
        uint256 collectCount;
        address collectModule;
        address collectNFT;
        address gatedModule;
        uint timestamp;
    }
}
