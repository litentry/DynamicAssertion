# Token Holding Amount Contract

## Guide to Adding a New Token

This guide explains how to add a new token to our existing token holding amount Verifiable Credentials (VC) contract, using **Bean** as an example. We’ll define the token’s configuration and add it to the TokenMapping contract.

### Step 1: Define the Token Configuration

Create a new token configuration library for **Bean**. This will include range assertions and network information.

```solidity
pragma solidity ^0.8.8;

import "../../libraries/Identities.sol";
import "../Constants.sol";

library Bean {
    // Define a range array for assertion clause generation, e.g. $holding_amount > 0, $holding_amount && $holding_amount < 1500, $holding_amount > 50000.
    function getTokenRanges() internal pure returns (TokenInfoRanges memory) {
        uint256[] memory ranges = new uint256[](5);
        ranges[0] = 0;
        ranges[1] = 1500;
        ranges[2] = 5000;
        ranges[3] = 10000;
        ranges[4] = 50000;


        return TokenInfoRanges(ranges, 0);
    }

    // Define a token info network array to config token address, data provider and token decimals for current token in different networks. 
    function getTokenNetworks()
        internal
        pure
        returns (TokenInfoNetwork[] memory)
    {
        TokenInfoNetwork[] memory networks = new TokenInfoNetwork[](2);
        networks[0] = TokenInfoNetwork(
            Web3Networks.Bsc,
            "0x07da81e9a684ab87fad7206b3bc8d0866f48cc7c", // Token address on BSC
            DataProviderTypes.NoderealClient, // Data provider
            18 // Token decimals
        );
        networks[1] = TokenInfoNetwork(
            Web3Networks.Combo,
            "0xba7b9936a965fac23bb7a8190364fa60622b3cff", // Token address on Combo
            DataProviderTypes.NoderealClient,
            18
        );
        return networks;
    }
}
```

### Step 2: Add the Token to the TokenMapping Contract

```solidity
import { Bean } from "./Bean.sol";

contract TokenMapping is TokenQueryLogic {
    constructor() {
        ...
        // registers the Bean token along with its holding ranges and network details.
        setTokenInfo("bean", Bean.getTokenRanges(), Bean.getTokenNetworks());
    }
}
```

## How to Add a New Data Provider for a Token?

This guide demonstrates how to add a new data provider, using **NoderealClient** as an example. You’ll define the new provider and integrate it into the token balance query logic.

### Step 1: Add the Data Provider Type

First, add a new constant for the data provider in the **DataProviderTypes** library located in `Constants.sol`.

```solidity
library DataProviderTypes {
    ...
    uint8 public constant NoderealClient = 4;
}
```

### Step 2: Create the **NoderealClient** Library

Next, create the **NoderealClient** library to interact with the external API and retrieve token balances. The library should include methods to query balances. For different external API, they may support some of the blockchain network, in case a token exists in blockchain network A but the external API used doesn't support blockchain network A, then we can filter this network so we don't make unnecessary call to the external API for the blockchain network that it doesn't support. And in the generated Verifiable Credentials, we will included the blockchain network set that we calculated the token balance on so that the VC user will know the final result is based on what exact blockchain networks.

```solidity
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/Http.sol";
import "../libraries/Identities.sol";
import "../libraries/Utils.sol";

library NoderealClient {
    function getTokenBalance(
        uint32 network,
        string memory secret,
        string memory tokenContractAddress,
        string memory account
    ) internal returns (bool, uint256) {
        HttpHeader[] memory headers = new HttpHeader[](0);
        string memory request;

        string memory encodePackedUrl = string(
            abi.encodePacked(getNetworkUrl(network), secret)
        );
        // For Native Token, call the method: eth_getBalance, if one token is the native token for the current network, the token contract address will be config to `Native Token`.
        if (Strings.equal(tokenContractAddress, "Native Token")) {
            // Use eth_getBalance method
            request = string(
                abi.encodePacked(
                    '{"jsonrpc": "2.0", "method": "eth_getBalance", "id": 1, "params": ["',
                    account,
                    '", "latest"]}'
                )
            );
        } else if (bytes(tokenContractAddress).length == 42) {
            // For non-Native Token, call the method: nr_getTokenBalance20.
            request = string(
                abi.encodePacked(
                    '{"jsonrpc": "2.0", "method": "nr_getTokenBalance20", "id": 1, "params": ["',
                    tokenContractAddress,
                    '","',
                    account,
                    '", "latest"]}'
                )
            );
        } else {
            return (false, 0);
        }
        (bool result, string memory balance) = Http.PostString(
            encodePackedUrl,
            "/result",
            request,
            headers
        );
        if (result) {
            // The result value is hex string, need to convert it to a number value.
            return Utils.hexToNumber(balance);
        } else {
            return (false, 0);
        }
    }

    // Define which networks are support by this client.
    function isSupportedNetwork(uint32 network) internal pure returns (bool) {
        return
            network == Web3Networks.Bsc ||
            network == Web3Networks.Ethereum ||
            network == Web3Networks.Combo;
    }

    // For Nodereal, different networks have different API URLs.
    function getNetworkUrl(
        uint32 network
    ) internal pure returns (string memory url) {
        if (network == Web3Networks.Bsc) {
            url = "https://bsc-mainnet.nodereal.io/v1/";
        } else if (network == Web3Networks.Ethereum) {
            url = "https://eth-mainnet.nodereal.io/v1/";
        } else if (network == Web3Networks.Combo) {
            url = "https://combo-mainnet.nodereal.io/v1/";
        }
    }
}
```

### Step 3: Integrate the New Data Provider into TokenQueryLogic

Finally, use the newly added NoderealClient in the TokenQueryLogic contract to query balances for the data provider supported networks.

```solidity
abstract contract TokenQueryLogic is TokenHoldingAmount {
    function queryBalance(
        Identity memory identity,
        uint32 network,
        string[] memory secrets,
        string memory tokenName,
        TokenInfo memory token
    ) internal override returns (uint256) {
        (bool identityToStringSuccess, string memory identityString) = Utils
            .identityToString(network, identity.value);

        if (identityToStringSuccess) {
            uint256 totalBalance = 0;

            // Retrieve token information for the specified network
            (
                string memory tokenContractAddress,
                uint8 dataProviderType,
                uint8 decimals
            ) = getTokenInfoNetwork(token, network);
            uint8 tokenDecimals = token.maxDecimals;
            uint8 tokenDecimalsDiff = tokenDecimals - decimals;

            // Use NoderealClient to query balances for supported networks
            if (
                dataProviderType == DataProviderTypes.NoderealClient &&
                NoderealClient.isSupportedNetwork(network)
            ) {
                (bool success, uint256 balance) = NoderealClient
                    .getTokenBalance(
                        network,
                        secrets[1],
                        tokenContractAddress,
                        identityString
                    );
                if (success) {
                    // Nodereal returns balance without decimals, so need multiply by the diff between maxDecimals and decimals.
                    totalBalance += balance * 10 ** tokenDecimalsDiff;
                }
            }
            ...
            return totalBalance;
        }
        return 0;
    }
}
```
