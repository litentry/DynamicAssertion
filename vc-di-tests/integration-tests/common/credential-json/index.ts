import { CorePrimitivesAssertionNetworkWeb3Network } from '@litentry/parachain-api'

import TokenMappingJson from './TokenMapping.json' assert { type: 'json' }
import PlatformUserJson from './PlatformUser.json' assert { type: 'json' }

export const TokenMapping = TokenMappingJson as CredentialDefinition[]
export const PlatformUser = PlatformUserJson as CredentialDefinition[]

// Pls do not change the order here
// If there are any new ones, please add them at the end of the array
export const credentialsJson = [...TokenMapping, ...PlatformUser]

export interface CredentialDefinition {
    contractName: string
    name: string
    parameter: string
    dataProvider: string
    network: CorePrimitivesAssertionNetworkWeb3Network['type']
    mockDid: string
    mockWeb3Network: string
    expectedCredentialValue: boolean
    // The link to find the linking address,  may be etherscan, or it may be the link of dataprovider, etc.
    addressSource: string
}
