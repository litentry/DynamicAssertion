// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;
import "../libraries/Http.sol";
import "../libraries/Utils.sol";
import "../libraries/Identities.sol";

library BOPClient {
    function talentAsset(string memory account) internal returns (bool, bool) {
        string memory url = "https://bop.burve.workers.dev/?address=";

        url = string(abi.encodePacked(url, account));

        HttpHeader[] memory headers = new HttpHeader[](0);
        return Http.GetBool(url, "/data", headers);
    }
}
