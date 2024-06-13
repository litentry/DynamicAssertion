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

import "../libraries/Identities.sol";
import "../libraries/Http.sol";
import "../libraries/Utils.sol";
import { TokenHoldingAmount } from "./TokenHoldingAmount.sol";

abstract contract BRC20 is TokenHoldingAmount {
	function getTokenDecimals() internal pure override returns (uint8) {
		return 18;
	}

	function queryBalance(
		Identity memory identity,
		uint32 network,
		string[] memory secrets
	) internal virtual override returns (uint256) {
		(bool identityToStringSuccess, string memory identityString) = Utils
			.identityToString(network, identity.value);
		if (identityToStringSuccess) {
			// https://geniidata.readme.io/reference/get-brc20-tick-list-copy
			string memory url = string(
				abi.encodePacked(
					// "https://api.geniidata.com/api/1/brc20/balance",
					// below url is used for test against mock server
					"http://localhost:19529/api/1/brc20/balance",
					"?tick=",
					getTokenName(),
					"&address=",
					identityString
				)
			);

			HttpHeader[] memory headers = new HttpHeader[](1);
			headers[0] = HttpHeader("api-key", secrets[0]);

			(bool success, string memory value) = Http.GetString(
				url,
				"/data/list/0/available_balance",
				headers
			);

			if (success) {
				(bool parseDecimalSuccess, uint256 result) = Utils.parseDecimal(
					value,
					getTokenDecimals()
				);
				if (parseDecimalSuccess) {
					return result;
				}
			}
		}
		return 0;
	}

	function isSupportedNetwork(
		uint32 network
	) internal pure override returns (bool) {
		return network == Web3Networks.BitcoinP2tr;
	}
}
