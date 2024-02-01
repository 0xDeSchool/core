// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISubscribeModule} from '../../interfaces/ISubscribeModule.sol';

contract RevertSubscribeModule is ISubscribeModule {
    function processSubscribe(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bool, string memory) {
        revert('RevertSubscribeModule');
    }
}
