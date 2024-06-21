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

// brc20
import { TokenLogic } from "./TokenLogic.sol";
import { Btcs } from "./brc20/Btcs.sol";
import { Cats } from "./brc20/Cats.sol";
import { Long } from "./brc20/Long.sol";
import { Mmss } from "./brc20/Mmss.sol";
import { Ordi } from "./brc20/Ordi.sol";
import { Rats } from "./brc20/Rats.sol";
import { Sats } from "./brc20/Sats.sol";

// erc20
import { Ada } from "./erc20/Ada.sol";
import { Amp } from "./erc20/Amp.sol";
import { Atom } from "./erc20/Atom.sol";
import { Bch } from "./erc20/Bch.sol";
import { Bean } from "./erc20/Bean.sol";
import { Bnb } from "./erc20/Bnb.sol";
import { Comp } from "./erc20/Comp.sol";
import { Cro } from "./erc20/Cro.sol";
import { Crv } from "./erc20/Crv.sol";
import { Dai } from "./erc20/Dai.sol";
import { Doge } from "./erc20/Doge.sol";
import { Dydx } from "./erc20/Dydx.sol";
import { Etc } from "./erc20/Etc.sol";
import { Eth } from "./erc20/Eth.sol";
import { Fil } from "./erc20/Fil.sol";
import { Grt } from "./erc20/Grt.sol";
import { Gtc } from "./erc20/Gtc.sol";
import { Gusd } from "./erc20/Gusd.sol";
import { Imx } from "./erc20/Imx.sol";
import { Inj } from "./erc20/Inj.sol";
import { Leo } from "./erc20/Leo.sol";
import { Link } from "./erc20/Link.sol";
import { Lit } from "./erc20/Lit.sol";
import { Matic } from "./erc20/Matic.sol";
import { Mcrt } from "./erc20//Mcrt.sol";
import { Nfp } from "./erc20/Nfp.sol";
import { People } from "./erc20/People.sol";
import { Shib } from "./erc20//Shib.sol";
import { Sol } from "./erc20/Sol.sol";
import { SpaceId } from "./erc20/SpaceId.sol";
import { Ton } from "./erc20/Ton.sol";
import { Trx } from "./erc20/Trx.sol";
import { Tusd } from "./erc20/Tusd.sol";
import { Uni } from "./erc20/Uni.sol";
import { Usdc } from "./erc20/Usdc.sol";
import { Usdt } from "./erc20/Usdt.sol";
import { Wbtc } from "./erc20//Wbtc.sol";
import { Cvx } from "./erc20/Cvx.sol";
import { Usdd } from "./erc20/Usdd.sol";
contract BRC20Mapping is TokenLogic {
	constructor() {
		// btcs
		tokenNames["btcs"] = Btcs.getTokenName();
		tokenRanges["btcs"] = Btcs.getTokenRanges();

		// cats
		tokenNames["cats"] = Cats.getTokenName();
		tokenRanges["cats"] = Cats.getTokenRanges();

		// long
		tokenNames["long"] = Long.getTokenName();
		tokenRanges["long"] = Long.getTokenRanges();

		// long
		tokenNames["mmss"] = Mmss.getTokenName();
		tokenRanges["mmss"] = Mmss.getTokenRanges();

		// ordi
		tokenNames["ordi"] = Ordi.getTokenName();
		tokenRanges["ordi"] = Ordi.getTokenRanges();

		// rats
		tokenNames["rats"] = Rats.getTokenName();
		tokenRanges["rats"] = Rats.getTokenRanges();

		// sats
		tokenNames["sats"] = Sats.getTokenName();
		tokenRanges["sats"] = Sats.getTokenRanges();

        	// ada
		tokenNames["ada"] = Ada.getTokenName();
		tokenRanges["ada"] = Ada.getTokenRanges();
		tokenBscAddress["ada"] = Ada.getTokenBscAddress();
		tokenEthereumAddress["ada"] = Ada.getTokenEthereumAddress();

		// amp
		tokenNames["amp"] = Amp.getTokenName();
		tokenRanges["amp"] = Amp.getTokenRanges();
		tokenBscAddress["amp"] = Amp.getTokenBscAddress();
		tokenEthereumAddress["amp"] = Amp.getTokenEthereumAddress();

		// atom
		tokenNames["atom"] = Atom.getTokenName();
		tokenRanges["atom"] = Atom.getTokenRanges();
		tokenBscAddress["atom"] = Atom.getTokenBscAddress();
		tokenEthereumAddress["atom"] = Atom.getTokenEthereumAddress();

		// bch
		tokenNames["bch"] = Bch.getTokenName();
		tokenRanges["bch"] = Bch.getTokenRanges();
		tokenBscAddress["bch"] = Bch.getTokenBscAddress();
		tokenEthereumAddress["bch"] = Bch.getTokenEthereumAddress();

		// bean
		tokenNames["bean"] = Bean.getTokenName();
		tokenRanges["bean"] = Bean.getTokenRanges();
		tokenBscAddress["bean"] = Bean.getTokenBscAddress();
		tokenEthereumAddress["bean"] = Bean.getTokenEthereumAddress();

		// bnb
		tokenNames["bnb"] = Bnb.getTokenName();
		tokenRanges["bnb"] = Bnb.getTokenRanges();
		tokenBscAddress["bnb"] = Bnb.getTokenBscAddress();
		tokenEthereumAddress["bnb"] = Bnb.getTokenEthereumAddress();

		// comp
		tokenNames["comp"] = Comp.getTokenName();
		tokenRanges["comp"] = Comp.getTokenRanges();
		tokenBscAddress["comp"] = Comp.getTokenBscAddress();
		tokenEthereumAddress["comp"] = Comp.getTokenEthereumAddress();

		// cro
		tokenNames["cro"] = Cro.getTokenName();
		tokenRanges["cro"] = Cro.getTokenRanges();
		tokenBscAddress["cro"] = Cro.getTokenBscAddress();
		tokenEthereumAddress["cro"] = Cro.getTokenEthereumAddress();

		// crv
		tokenNames["crv"] = Crv.getTokenName();
		tokenRanges["crv"] = Crv.getTokenRanges();
		tokenBscAddress["crv"] = Crv.getTokenBscAddress();
		tokenEthereumAddress["crv"] = Crv.getTokenEthereumAddress();

		// cvx
		tokenNames["cvx"] = Cvx.getTokenName();
		tokenRanges["cvx"] = Cvx.getTokenRanges();
		tokenBscAddress["cvx"] = Cvx.getTokenBscAddress();
		tokenEthereumAddress["cvx"] = Cvx.getTokenEthereumAddress();

		// dai
		tokenNames["dai"] = Dai.getTokenName();
		tokenRanges["dai"] = Dai.getTokenRanges();
		tokenBscAddress["dai"] = Dai.getTokenBscAddress();
		tokenEthereumAddress["dai"] = Dai.getTokenEthereumAddress();

		// doge
		tokenNames["doge"] = Doge.getTokenName();
		tokenRanges["doge"] = Doge.getTokenRanges();
		tokenBscAddress["doge"] = Doge.getTokenBscAddress();
		tokenEthereumAddress["doge"] = Doge.getTokenEthereumAddress();

		// dydx
		tokenNames["dydx"] = Dydx.getTokenName();
		tokenRanges["dydx"] = Dydx.getTokenRanges();
		tokenBscAddress["dydx"] = Dydx.getTokenBscAddress();
		tokenEthereumAddress["dydx"] = Dydx.getTokenEthereumAddress();

		// etc
		tokenNames["etc"] = Etc.getTokenName();
		tokenRanges["etc"] = Etc.getTokenRanges();
		tokenBscAddress["etc"] = Etc.getTokenBscAddress();
		tokenEthereumAddress["etc"] = Etc.getTokenEthereumAddress();

		// eth
		tokenNames["eth"] = Eth.getTokenName();
		tokenRanges["eth"] = Eth.getTokenRanges();
		tokenBscAddress["eth"] = Eth.getTokenBscAddress();
		tokenEthereumAddress["eth"] = Eth.getTokenEthereumAddress();

		// fil
		tokenNames["fil"] = Fil.getTokenName();
		tokenRanges["fil"] = Fil.getTokenRanges();
		tokenBscAddress["fil"] = Fil.getTokenBscAddress();
		tokenEthereumAddress["fil"] = Fil.getTokenEthereumAddress();

		// grt
		tokenNames["grt"] = Grt.getTokenName();
		tokenRanges["grt"] = Grt.getTokenRanges();
		tokenBscAddress["grt"] = Grt.getTokenBscAddress();
		tokenEthereumAddress["grt"] = Grt.getTokenEthereumAddress();

		// gtc
		tokenNames["gtc"] = Gtc.getTokenName();
		tokenRanges["gtc"] = Gtc.getTokenRanges();
		tokenBscAddress["gtc"] = Gtc.getTokenBscAddress();
		tokenEthereumAddress["gtc"] = Gtc.getTokenEthereumAddress();

		// gusd
		tokenNames["gusd"] = Gusd.getTokenName();
		tokenRanges["gusd"] = Gusd.getTokenRanges();
		tokenBscAddress["gusd"] = Gusd.getTokenBscAddress();
		tokenEthereumAddress["gusd"] = Gusd.getTokenEthereumAddress();

		// imx
		tokenNames["imx"] = Imx.getTokenName();
		tokenRanges["imx"] = Imx.getTokenRanges();
		tokenBscAddress["imx"] = Imx.getTokenBscAddress();
		tokenEthereumAddress["imx"] = Imx.getTokenEthereumAddress();

		// inj
		tokenNames["inj"] = Inj.getTokenName();
		tokenRanges["inj"] = Inj.getTokenRanges();
		tokenBscAddress["inj"] = Inj.getTokenBscAddress();
		tokenEthereumAddress["inj"] = Inj.getTokenEthereumAddress();

		// leo
		tokenNames["leo"] = Leo.getTokenName();
		tokenRanges["leo"] = Leo.getTokenRanges();
		tokenBscAddress["leo"] = Leo.getTokenBscAddress();
		tokenEthereumAddress["leo"] = Leo.getTokenEthereumAddress();

		// link
		tokenNames["link"] = Link.getTokenName();
		tokenRanges["link"] = Link.getTokenRanges();
		tokenBscAddress["link"] = Link.getTokenBscAddress();
		tokenEthereumAddress["link"] = Link.getTokenEthereumAddress();

		// lit
		tokenNames["lit"] = Lit.getTokenName();
		tokenRanges["lit"] = Lit.getTokenRanges();
		tokenBscAddress["lit"] = Lit.getTokenBscAddress();
		tokenEthereumAddress["lit"] = Lit.getTokenEthereumAddress();

		// matic
		tokenNames["matic"] = Matic.getTokenName();
		tokenRanges["matic"] = Matic.getTokenRanges();
		tokenBscAddress["matic"] = Matic.getTokenBscAddress();
		tokenEthereumAddress["matic"] = Matic.getTokenEthereumAddress();

		// mcrt
		tokenNames["mcrt"] = Mcrt.getTokenName();
		tokenRanges["mcrt"] = Mcrt.getTokenRanges();
		tokenBscAddress["mcrt"] = Mcrt.getTokenBscAddress();
		tokenEthereumAddress["mcrt"] = Mcrt.getTokenEthereumAddress();

		// nfp
		tokenNames["nfp"] = Nfp.getTokenName();
		tokenRanges["nfp"] = Nfp.getTokenRanges();
		tokenBscAddress["nfp"] = Nfp.getTokenBscAddress();
		tokenEthereumAddress["nfp"] = Nfp.getTokenEthereumAddress();

		// people
		tokenNames["people"] = People.getTokenName();
		tokenRanges["people"] = People.getTokenRanges();
		tokenBscAddress["people"] = People.getTokenBscAddress();
		tokenEthereumAddress["people"] = People.getTokenEthereumAddress();

		// shib
		tokenNames["shib"] = Shib.getTokenName();
		tokenRanges["shib"] = Shib.getTokenRanges();
		tokenBscAddress["shib"] = Shib.getTokenBscAddress();
		tokenEthereumAddress["shib"] = Shib.getTokenEthereumAddress();

		// sol
		tokenNames["sol"] = Sol.getTokenName();
		tokenRanges["sol"] = Sol.getTokenRanges();
		tokenBscAddress["sol"] = Sol.getTokenBscAddress();
		tokenEthereumAddress["sol"] = Sol.getTokenEthereumAddress();

		// spaceid
		tokenNames["spaceid"] = SpaceId.getTokenName();
		tokenRanges["spaceid"] = SpaceId.getTokenRanges();
		tokenBscAddress["spaceid"] = SpaceId.getTokenBscAddress();
		tokenEthereumAddress["spaceid"] = SpaceId.getTokenEthereumAddress();

		// ton
		tokenNames["ton"] = Ton.getTokenName();
		tokenRanges["ton"] = Ton.getTokenRanges();
		tokenBscAddress["ton"] = Ton.getTokenBscAddress();
		tokenEthereumAddress["ton"] = Ton.getTokenEthereumAddress();

		// trx
		tokenNames["trx"] = Trx.getTokenName();
		tokenRanges["trx"] = Trx.getTokenRanges();
		tokenBscAddress["trx"] = Trx.getTokenBscAddress();
		tokenEthereumAddress["trx"] = Trx.getTokenEthereumAddress();

		// tusd
		tokenNames["tusd"] = Tusd.getTokenName();
		tokenRanges["tusd"] = Tusd.getTokenRanges();
		tokenBscAddress["tusd"] = Tusd.getTokenBscAddress();
		tokenEthereumAddress["tusd"] = Tusd.getTokenEthereumAddress();

		// uni
		tokenNames["uni"] = Uni.getTokenName();
		tokenRanges["uni"] = Uni.getTokenRanges();
		tokenBscAddress["uni"] = Uni.getTokenBscAddress();
		tokenEthereumAddress["uni"] = Uni.getTokenEthereumAddress();

		// usdc
		tokenNames["usdc"] = Usdc.getTokenName();
		tokenRanges["usdc"] = Usdc.getTokenRanges();
		tokenBscAddress["usdc"] = Usdc.getTokenBscAddress();
		tokenEthereumAddress["usdc"] = Usdc.getTokenEthereumAddress();

		// usdd
		tokenNames["usdd"] = Usdd.getTokenName();
		tokenRanges["usdd"] = Usdd.getTokenRanges();
		tokenBscAddress["usdd"] = Usdd.getTokenBscAddress();
		tokenEthereumAddress["usdd"] = Usdd.getTokenEthereumAddress();

		// usdt
		tokenNames["usdt"] = Usdt.getTokenName();
		tokenRanges["usdt"] = Usdt.getTokenRanges();
		tokenBscAddress["usdt"] = Usdt.getTokenBscAddress();
		tokenEthereumAddress["usdt"] = Usdt.getTokenEthereumAddress();

		// wbtc
		tokenNames["wbtc"] = Wbtc.getTokenName();
		tokenRanges["wbtc"] = Wbtc.getTokenRanges();
		tokenBscAddress["wbtc"] = Wbtc.getTokenBscAddress();
		tokenEthereumAddress["wbtc"] = Wbtc.getTokenEthereumAddress();
	}
}
