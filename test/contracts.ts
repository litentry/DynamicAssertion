import { ethers } from "hardhat"
import { expect } from "chai"
// todo: add more tests
describe("contracts", () => {
    it("should return the bytecode of the contracts", async () => {
        const A1Contract = await ethers.getContractFactory("A1")
        const A6Contract = await ethers.getContractFactory("A6")
        const A20Contract = await ethers.getContractFactory("A20")

        expect(A1Contract.bytecode).to.be.ok
        expect(A6Contract.bytecode).to.be.ok
        expect(A20Contract.bytecode).to.be.ok
        console.log("A1 bytecode🚀🚀🚀🚀🚀🚀:", A1Contract.bytecode)
        console.log("A6 bytecode🚀🚀🚀🚀🚀:", A6Contract.bytecode)
        console.log("A20 bytecode🚀🚀🚀🚀🚀:", A20Contract.bytecode)
    })
})
