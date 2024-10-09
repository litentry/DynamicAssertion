
# Basic Contract Template

A new contract must extend DynamicAssertion. Below is the template:

```solidity
pragma solidity ^0.8.8;

import "./libraries/AssertionLogic.sol";
import "./libraries/Identities.sol";
import "./DynamicAssertion.sol";

contract SampleContract is DynamicAssertion {
    function execute(
        Identity[] memory identities,
        string[] memory secrets,  // Immutable secret values set at deployment, e.g., API authorization token.
        bytes memory params       // Additional caller-supplied params, use `abi.decode` to extract values.
    )
        public
        override
        returns (
            string memory,        // Description of the assertion.
            string memory,        // Assertion type.
            string[] memory,      // Assertions built using composite conditions.
            string memory,        // JSON schema URL for VC result validation.
            bool                  // Assertion result.
        )
    {
        // Assertion description that decided by you.
        string memory description = "Some description";
        // Assertion type name that decided by you.
        string memory assertion_type = "Some assertion type";
        // The schema_url is the JSON schema that use to verify your result VC.
        schema_url = "https://raw.githubusercontent.com/litentry/vc-jsonschema/main/dist/schemas/xxx/xxx.json";

        // Calculate the result value for your business.
        bool result = true;

        // Assemble the assertion condition and clause what you need.
        AssertionLogic.CompositeCondition memory cc = AssertionLogic
            .CompositeCondition(new AssertionLogic.Condition[](1), true);
        AssertionLogic.andOp(
            cc,
            0,
            "$some_key",
            AssertionLogic.Op.Equal,
            "true"
        );
        string[] memory assertions = new string[](1);
        assertions[0] = AssertionLogic.toString(cc);

        // The returned result will be use by parachain to assemble VC result and return to client.
        return (description, assertion_type, assertions, schema_url, result);
    }
}
```

## How to Call HTTP API in Contract?

The following template demonstrates calling an HTTP API:

```solidity
import "./libraries/Http.sol";

string memory url = string(
    abi.encodePacked(
        "https://example.com/api?account=",
        account
    )
);
// Use the JSON pointer to retrieve value from the API response.
string memory jsonPointer = "/success";
HttpHeader[] memory headers = new HttpHeader[](1);
// Use value from secrets as Authorization token.
headers[0] = HttpHeader("Authorization", secrets[0]);

// The `success = true` means call `Http.GetBool` successfully.
// The result is the value that get using JSON pointer from the API response.
(bool success, bool value) = Http.GetBool(
    url,
    jsonPointer,
    headers
);
if (success) {
    // The value can be use here.
}
```

### Supported HTTP Functions

The following HTTP functions are available for use:

- `Http.GetI64(string memory url, string memory jsonPointer, HttpHeader[] memory headers)`: Executes a GET request and retrieves an I64 value from the response using a JSON pointer.

- `Http.GetBool(string memory url, string memory jsonPointer, HttpHeader[] memory headers)`: Executes a GET request and retrieves an Bool value from the response using a JSON pointer.

- `Http.GetString(string memory url, string memory jsonPointer, HttpHeader[] memory headers)`: Executes a GET request and retrieves an String value from the response using a JSON pointer.

- `Http.Get(string memory url, HttpHeader[] memory headers)`: Executes a GET request and return a String value.

Similarly, the following POST methods are supported:

- `Http.PostI64`, `Http.PostBool`, `Http.PostString`, and `Http.Post`: These behave the same as their GET counterparts but use POST requests.

### Processing Complex API Responses

#### Handling Decimal Values

Example response:

```json
{
    value: "123456789.123456789"
}
```

Example code:

```solidity
import "./libraries/Http.sol";
import "./libraries/Utils.sol";

string memory url = string(
    abi.encodePacked(
        "https://example.com/api?account=",
        account
    )
);

string memory jsonPointer = "/value";
HttpHeader[] memory headers = new HttpHeader[](0);

(bool success, string memory value) = Http.GetString(
    url,
    jsonPointer,
    headers
);

if (getSuccess) {
    // The 9 is decimals of string number, solidity does not support decimal, so need multiply decimals to convert it to an integer.
    (bool parseSuccess, uint256 parsedValue) = Utils.parseDecimal(getResult, 9);
    if (parseSuccess) {
        // The parsedValue can be use here.
    }
}
```

#### Handling Multiple Values from API Response

Example response:

```json
[
    {
        count: 1
    },
    {
        count: 2
    },
    ...
]
```

Example code:

```solidity
import "./libraries/Http.sol";
import "./libraries/Json.sol";

string memory url = string(
    abi.encodePacked(
        "https://example.com/api?account=",
        account
    )
);

HttpHeader[] memory headers = new HttpHeader[](0);

// Firstly, all the http API.
(bool success, string memory value) = Http.Get(
    url,
    headers
);

int64 total = 0;
if (getSuccess) {
    // Secondary, calculate the array length of the return API response.
    (bool arrayLenSuccess, int64 arrayLen) = Json.getArrayLen(
        value,
        "" // The empty pointer means from root.
    );
    if (arrayLenSuccess) {
        // Tertiary, get the count value of each array item and sum.
        for (uint256 i = 0; i < uint256(int256(arrayLen)); i++) {
            (
                bool getI64Success,
                i64 count
            ) = Json.getI64(
                    tokensResponse,
                    string(
                        abi.encodePacked(
                            "/",
                            Strings.toString(i),
                            "/count"
                        )
                    )
                );
            if (getI64Success) {
                total += count;
            }
        }
    }
}
```

## How to Logging?

### Precompiles logging

This method logs messages into the contract’s call context. The log messages will be returned to the client if the return_log param is true when calling the contract.

Example Code:

```solidity
import "./libraries/Logging.sol";

Logging.debug("This is a debug message.");

Logging.info("This is a info message.");

Logging.warn("This is a warn message.");

Logging.fatal("This is a fatal message.");

Logging.error("This is a error message.");
```

Example CLI Usage:

```shell
# return_log = true
./bin/litentry-cli trusted -d request-vc did:litentry:evm:0x22F9dCF4647084d6C31b2765F6910cd85C178C18 -a "dynamic 4431df14713fe74b7ab298cdbb50c1ca18f7982f 0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000461746f6d00000000000000000000000000000000000000000000000000000000 true"
# return_log = false
./bin/litentry-cli trusted -d request-vc did:litentry:evm:0x22F9dCF4647084d6C31b2765F6910cd85C178C18 -a "dynamic 4431df14713fe74b7ab298cdbb50c1ca18f7982f 0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000461746f6d00000000000000000000000000000000000000000000000000000000 false"
```

### Hardhat logging

This method is specifically for debugging while running contracts in a Hardhat environment. It won’t log messages once the contract is deployed to an EVM. For more details, refer to [Hardhat’s Debugging Documentation](https://hardhat.org/tutorial/debugging-with-hardhat-network#solidity-console-log).

Example Code:

```solidity
import "hardhat/console.sol";

console.log("This is a log message", "msg1", "msg2");
```
