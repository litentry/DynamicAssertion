import type { IntegrationTestContext } from '../common-types'

import type { CorePrimitivesIdentity } from '@litentry/parachain-api'
import type { HexString } from '@polkadot/util/types'

export async function buildIdentityHelper(
    address: HexString | string,
    type: CorePrimitivesIdentity['type'],
    context: IntegrationTestContext
): Promise<CorePrimitivesIdentity> {
    const identity = {
        [type]: address,
    }
    return context.api.createType('CorePrimitivesIdentity', identity)
}
