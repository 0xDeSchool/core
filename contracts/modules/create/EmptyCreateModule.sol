// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICreateModule} from '../../interfaces/ICreateModule.sol';

contract EmptyCreateModule is ICreateModule {
    function processCreate(
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bool, string memory) {
        return (true, '');
    }
}