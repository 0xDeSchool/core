// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ERC165Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol';
import {UpgradeableBase} from '../../upgradeability/UpgradeableBase.sol';
import {RequiredHubUpgradeable} from '../../base/RequiredHubUpgradeable.sol';
import {ICollectModule} from '../../interfaces/ICollectModule.sol';
import {ITokenTransfer} from '../../interfaces/ITokenTransfer.sol';
import {Errors} from '../../libs/Errors.sol';
import {IAssetHub} from '../../interfaces/IAssetHub.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

struct FeeConfig {
    address currency;
    address recipient;
    uint256 amount;
}

contract FeeCollectModule is
    UpgradeableBase,
    RequiredHubUpgradeable,
    ERC165Upgradeable,
    ICollectModule
{
    using SafeERC20 for IERC20;

    mapping(uint256 assetId => FeeConfig config) internal _feeConfig;

    event FeeConfigChanged(uint256 indexed assetId, FeeConfig config);

    error FeeConfigNotValid();

    constructor() {}

    function initialize(address hub) external initializer {
        __UUPSUpgradeable_init();
        __RequiredHub_init(hub);
        __ERC165_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyHubOwner {}

    function version() external view virtual override returns (string memory) {
        return '1.0.0';
    }

    function setFeeConfig(uint256 assetId, FeeConfig memory feeConfig) external {
        _checkAssetOwner(assetId, msg.sender);
        if (feeConfig.amount == 0) {
            // no fee, currency must be address(0)
            require(feeConfig.currency == address(0), 'FeeCollectModule: invalid fee config');
        }
        _setFeeConfig(assetId, feeConfig);
    }

    function initialModule(
        address /* publisher */,
        uint256 assetId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        FeeConfig memory feeConfig = abi.decode(data, (FeeConfig));
        if (feeConfig.amount == 0) {
            // no fee, currency must be address(0)
            require(feeConfig.currency == address(0), 'FeeCollectModule: invalid fee config');
        }
        _setFeeConfig(assetId, feeConfig);
        return '';
    }

    function processCollect(
        address collector,
        address /* publisher */,
        uint256 assetId,
        bytes calldata
    ) external override onlyHub returns (bytes memory errMsg) {
        FeeConfig memory config = _feeConfig[assetId];
        if (config.amount == 0) {
            return '';
        }
        if (config.currency == address(0) || config.recipient == address(0)) {
            revert FeeConfigNotValid();
        }
        IERC20(config.currency).transferFrom(collector, config.recipient, config.amount);
        return '';
    }

    function getFeeConfig(uint256 assetId) external view returns (FeeConfig memory) {
        FeeConfig memory config = _feeConfig[assetId];
        if (config.currency == address(0) && config.amount == 0 && config.recipient == address(0)) {
            revert FeeConfigNotValid();
        }
        return config;
    }

    function _setFeeConfig(uint256 assetId, FeeConfig memory feeConfig) internal {
        _feeConfig[assetId] = feeConfig;
        emit FeeConfigChanged(assetId, feeConfig);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ICollectModule).interfaceId || super.supportsInterface(interfaceId);
    }
}
