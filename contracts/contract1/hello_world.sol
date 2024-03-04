// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract HelloWorld {
    string name = "zzq";

    function setName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return string(abi.encodePacked("Hello, ", name, "'s World !"));
    }
}
