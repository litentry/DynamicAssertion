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
        uint32[] memory networks = new uint32[](1);
        networks[0] = Web3Networks.Bsc;

        return networks;
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