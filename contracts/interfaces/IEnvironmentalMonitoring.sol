// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEnvironmentalMonitoring {
    function isAlertValid(uint256 alertId) external view returns (bool);
    function getStation(string calldata stationId) external view returns (
        string memory stationId_,
        string memory name,
        int256  latitude,
        int256  longitude,
        bool    active
    );
}
