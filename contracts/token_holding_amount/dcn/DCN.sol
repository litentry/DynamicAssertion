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

import "../Constants.sol";
import "../../libraries/Identities.sol";

library DCN {
    function getDefaultTokenNetworks() internal pure returns (uint32[] memory) {
        uint32[] memory networks = new uint32[](2);
        networks[0] = Web3Networks.Bsc;
        networks[1] = Web3Networks.Ethereum;

        return networks;
    }
    function getTokenRanges() internal pure returns (TokenInfoRanges memory) {
        uint256[] memory ranges = new uint256[](12);
        ranges[0] = 0;
        ranges[1] = 1;
        ranges[2] = 2;
        ranges[3] = 3;
        ranges[4] = 4;
        ranges[5] = 5;
        ranges[6] = 10;
        ranges[7] = 20;
        ranges[8] = 30;
        ranges[9] = 50;
        ranges[10] = 70;
        ranges[11] = 100;

        return TokenInfoRanges(ranges, 0);
    }
    function getTokenNetworks()
        internal
        pure
        returns (TokenInfoNetwork[] memory)
    {
        uint32[] memory defaultNetworks = DCN.getDefaultTokenNetworks();
        TokenInfoNetwork[] memory networks = new TokenInfoNetwork[](
            defaultNetworks.length
        );
        for (uint i = 0; i < defaultNetworks.length; i++) {
            networks[i] = TokenInfoNetwork(
                defaultNetworks[i],
                "",
                DataProviderTypes.DinNFTClient,
                0
            );
        }

        return networks;
    }
}
