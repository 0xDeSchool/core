// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Errors {
    error InitParamsInvalid();
    error NotHub();
    error Initialized();
    error TokenDoesNotExist();
    error AssetDoesNotExist();
    error CallerNotSubscribeNFT();
    error SubscribeModuleNotWhitelisted();
}