import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"

const config = {
	solidity: "0.8.11",
	networks: {
		hardhat: {
			allowUnlimitedContractSize: true,
		},
	},
}

export default config
