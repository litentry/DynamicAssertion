import { CorePrimitivesAssertionNetworkWeb3Network } from '@litentry/parachain-api'
import type { Codec } from '@polkadot/types-codec/types'
import type { U8aLike } from '@polkadot/util/types'

type AssertionGenericPayload =
    | string
    | Array<string | number | Codec | U8aLike>
    | Record<string, unknown>

import TokenMappingJson from './TokenMapping.json' assert { type: 'json' }

export const TokenMapping = TokenMappingJson as CredentialDefinition[]

export const credentialsJson = [...TokenMapping]

export interface CredentialDefinition {
    index: number
    contractName: string
    name: string
    parameter: string
    network: CorePrimitivesAssertionNetworkWeb3Network['type']
    mockDid: string
    mockWeb3Network: string
    expectedCredentialValue: boolean
    // The link to find the linking address,  may be etherscan, or it may be the link of dataprovider, etc.
    addressSource: string
}
