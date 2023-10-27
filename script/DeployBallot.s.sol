// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Ballot} from "../src/Ballot.sol";

contract DeployBallot is Script {
    string[] internal PARAMS = ["Tinubu", "Atiku", "Obi"];

    function run() external returns (Ballot) {
        vm.startBroadcast();

        Ballot ballot = new Ballot(PARAMS);
        vm.stopBroadcast();
        return ballot;
    }
}
