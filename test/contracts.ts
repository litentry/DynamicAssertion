import { ethers } from "hardhat"

// todo: add more tests
describe("contracts", () => {
	it("should return the bytecode of the contracts", async () => {
		const A1Contract = await ethers.getContractFactory("A1")
		const A6Contract = await ethers.getContractFactory("A6")
		const A20Contract = await ethers.getContractFactory("A20")

		console.log("A1 bytecode🚀🚀🚀🚀🚀🚀:", A1Contract.bytecode)
		console.log("A6 bytecode🚀🚀🚀🚀🚀:", A6Contract.bytecode)
		console.log("A20 bytecode🚀🚀🚀🚀🚀:", A20Contract.bytecode)
	})
})
