// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ERC165Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol';
import {UpgradeableBase} from '../../upgradeability/UpgradeableBase.sol';
import {INftAssetGatedModule} from '../../interfaces/INftAssetGatedModule.sol';
import {IAssetGatedModule} from '../../interfaces/IAssetGatedModule.sol';
import {RequiredHubUpgradeable} from '../../base/RequiredHubUpgradeable.sol';

enum NftGatedType {
    ERC20,
    ERC721,
    ERC1155
}

struct NftGatedConfig {
    address nftContract;
    NftGatedType nftType;
    uint256 tokenId;
    uint256 amount;
    bool isOr;
}

contract NftAssetGatedModule is
    UpgradeableBase,
    RequiredHubUpgradeable,
    ERC165Upgradeable,
    INftAssetGatedModule
{
    bytes4 public constant ERC721_INTERFACE = type(IERC721).interfaceId;
    bytes4 public constant ERC1155_INTERFACE = type(IERC1155).interfaceId;
    bytes4 public constant ERC20_INTERFACE = type(IERC20).interfaceId;

    mapping(uint256 => NftGatedConfig[]) internal nftGatedConfigs;

    event ConfigChanged(uint256 indexed assetId, NftGatedConfig[] config);

    error NftContractIsZeroAddress();
    error ContractTypeNotSupported(address);
    error ContractTypeNotMatched(address, NftGatedType);

    function initialize(address hub) external initializer {
        __UUPSUpgradeable_init();
        __RequiredHub_init(hub);
    }

    function version() external view virtual override returns (string memory) {
        return '1.0.0';
    }

    function setConfig(uint256 assetId, NftGatedConfig[] calldata config) external {
        _checkAssetOwner(assetId, msg.sender);
        _setConfig(assetId, config);
    }

    function getConfig(uint256 assetId) public view returns (NftGatedConfig[] memory) {
        return nftGatedConfigs[assetId];
    }

    function initialModule(
        address /* publisher */,
        uint256 assetId,
        bytes calldata data
    ) external onlyHub returns (bytes memory) {
        NftGatedConfig[] memory config = abi.decode(data, (NftGatedConfig[]));
        if (config.length == 0) {
            return '';
        }
        _setConfig(assetId, config);
        return '';
    }

    function isGated(uint256 assetId, address account) external view override returns (bool) {
        NftGatedConfig[] memory config = nftGatedConfigs[assetId];
        if (config.length == 0) {
            return true;
        }
        for (uint256 i = 0; i < config.length; i++) {
            bool isOr = i == 0 ? false : config[i].isOr;
            bool isPass;
            if (config[i].nftType == NftGatedType.ERC20) {
                isPass = IERC20(config[i].nftContract).balanceOf(account) >= config[i].amount;
            } else if (config[i].nftType == NftGatedType.ERC721) {
                isPass = IERC721(config[i].nftContract).balanceOf(account) >= config[i].amount;
            } else if (config[i].nftType == NftGatedType.ERC1155) {
                isPass =
                    IERC1155(config[i].nftContract).balanceOf(account, config[i].tokenId) >=
                    config[i].amount;
            }
            if (isOr && isPass) {
                return true;
            } else if (!isOr && !isPass) {
                return false;
            }
        }
        return true;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyHubOwner {}

    function _checkNftContract(NftGatedConfig memory config) internal view {
        if (config.nftContract == address(0)) {
            revert NftContractIsZeroAddress();
        }
        if (config.nftType == NftGatedType.ERC20) {
            if (!_isERC20(config.nftContract)) {
                revert ContractTypeNotMatched(config.nftContract, config.nftType);
            }
        } else if (config.nftType == NftGatedType.ERC721) {
            if (!_isERC721(config.nftContract)) {
                revert ContractTypeNotMatched(config.nftContract, config.nftType);
            }
        } else if (config.nftType == NftGatedType.ERC1155) {
            if (!_isERC1155(config.nftContract)) {
                revert ContractTypeNotMatched(config.nftContract, config.nftType);
            }
        } else {
            revert ContractTypeNotSupported(config.nftContract);
        }
    }

    function _setConfig(uint256 assetId, NftGatedConfig[] memory config) internal {
        for (uint256 i = 0; i < config.length; i++) {
            _checkNftContract(config[i]);
        }
        for (uint256 i = 0; i < config.length; i++) {
            nftGatedConfigs[assetId].push(config[i]);
        }
        emit ConfigChanged(assetId, config);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IAssetGatedModule).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _isERC721(address nftContract) internal view returns (bool) {
        return IERC721(nftContract).supportsInterface(ERC721_INTERFACE);
    }

    function _isERC1155(address nftContract) internal view returns (bool) {
        return IERC1155(nftContract).supportsInterface(ERC1155_INTERFACE);
    }

    function _isERC20(address /* nftContract */) internal pure returns (bool) {
        return true;
    }
}
