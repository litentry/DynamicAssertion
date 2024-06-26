![Logo](https://avatars.githubusercontent.com/u/51339301?s=200&v=4)

## Litentry Dynamic Assertion Contracts

This repo is the contracts part separated from the [litentry-parachain](https://github.com/litentry/litentry-parachain).

## System Requirements

-   Node.js
-   Typescript
-   [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#overview)
-   Solidity

## Configuration

-   [Solidity versions](https://hardhat.org/hardhat-runner/docs/advanced/multiple-solidity-versions)
-   [Configuration Variables](https://hardhat.org/hardhat-runner/docs/config#configuration)

## Getting started

1. Install Node V18

2. Clone this repo

3. Switch to the right Node.js version using NVM.

    ```typescript
    # From the repo's root
    nvm use
    ```

4. Install dependencies with `npm`

    ```typescript
    # From the repo's root
    npm install
    ```

5. Compile contracts

    ```typescript
    # From the repo's root
    npm run compile or npx hardhat compile
    ```

    [Compiled directory structure](https://hardhat.org/hardhat-runner/docs/advanced/artifacts#directory-structure)

6. Run ts-tests

    ```typescript
    # From the repo's root
    npm run test:all or npx hardhat test
    ```

    [More tesing contracts details](https://hardhat.org/hardhat-runner/docs/guides/test-contracts)
