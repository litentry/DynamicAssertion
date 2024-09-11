// Copyright 2020-2024 Trust Computing GmbH.
// This file is part of Litentry.
//
// Litentry is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Litentry is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Litentry.  If not, see <https://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.8;

import "../libraries/Http.sol";
import "../libraries/Identities.sol";
import "../libraries/Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

library DinNFTClient {
    function getTokenBalance(
        uint32 network,
        string memory identityString,
        string memory tokenName
    ) internal returns (uint256) {
        int256 dcnPower = getDcnPowerLevel(tokenName);
        string memory chainId;
        if (dcnPower == -1) {
            return 0;
        }
        if(network==Web3Networks.Ethereum){
            chainId = "1";
        }else if(network==Web3Networks.Bsc){
            chainId = "56";
        }else{
            return 0;
        }
        string memory encodePackedUrl = string(
            abi.encodePacked(
                // test against mock server => "http://localhost:19529/api/1/brc20/balance"
                "https://node.din.lol/api/chipperNode/owned/nodes",
                "?level=",
                Strings.toString(dcnPower),
                "&address=",
                identityString,
                "&chainId=",
                chainId
            )
        );
        HttpHeader[] memory headers = new HttpHeader[](1);
        // https://geniidata.readme.io/reference/get-brc20-tick-list-copy
        (bool success, string memory value) = Http.GetString(
            encodePackedUrl,
            "/data",
            headers
        );
        if (success) {
            (bool parseDecimalSuccess, uint256 result) = Utils.parseInt(value);
            if (parseDecimalSuccess) {
                return result;
            }
        }
        return 0;
    }
    function getDcnPowerLevel(
        string memory dcnName
    ) internal pure returns (int256) {
        for (int256 i = 0; i < 10; i++) {
            string memory dcnIndex;

            if (i < 10) {
                dcnIndex = string(
                    bytes.concat(bytes("0"), bytes(Strings.toString(i + 1)))
                );
            } else {
                dcnIndex = Strings.toString(i);
            }
            if (
                Strings.equal(
                    dcnName,
                    string(bytes.concat(bytes("dcn"), bytes(dcnIndex)))
                )
            ) {
                return i;
            }
        }
        return -1;
    }
    function isSupportedNetwork(uint32 network) internal pure returns (bool) {
        return network == Web3Networks.Bsc || network == Web3Networks.Ethereum;
    }
}
