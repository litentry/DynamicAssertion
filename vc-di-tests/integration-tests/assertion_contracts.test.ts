import { randomBytes, KeyObject } from 'crypto'
import { step } from 'mocha-steps'
import { buildValidations, initIntegrationTestContext } from './common/utils'
import { assertIsInSidechainBlock, assertVc } from './common/utils/assertion'
import {
    getSidechainNonce,
    getTeeShieldingKey,
    sendRequestFromTrustedCall,
    createSignedTrustedCallRequestVc,
    createSignedTrustedCallLinkIdentity,
    sendAesRequestFromGetter,
} from './common/di-utils' // @fixme move to a better place
import type { IntegrationTestContext } from './common/common-types'
import { aesKey } from './common/call'
import type {
    CorePrimitivesIdentity,
    LitentryValidationData,
    Web3Network,
} from '@litentry/parachain-api'
import fs from 'fs'
import path from 'path'
import { assert } from 'chai'
import { genesisSubstrateWallet, randomSubstrateWallet } from './common/helpers'
import { KeyringPair } from '@polkadot/keyring/types'
import { subscribeToEvents } from './common/transactions'
import {
    encryptWithTeeShieldingKey,
    PolkadotSigner,
} from './common/utils/crypto'
import { ethers } from 'ethers'
import { sleep } from './common/utils'
import { Bytes, Vec } from '@polkadot/types-codec'
import { u8aToHex } from '@polkadot/util'
import { byId } from '@litentry/chaindata'
import { $ as zx } from 'zx'
import { CredentialDefinition, credentialsJson } from './common/credential-json'

describe('Test Vc (direct request)', function () {
    let context: IntegrationTestContext = undefined as any
    let teeShieldingKey: KeyObject = undefined as any
    let aliceSubstrateIdentity: CorePrimitivesIdentity = undefined as any
    const substrateIdentities: CorePrimitivesIdentity[] = []

    let alice: KeyringPair = undefined as any
    // let contractBytecode = undefined as any
    const clientDir = process.env.LITENTRY_CLI_DIR
    const keyringPairs: KeyringPair[] = []
    const linkIdentityRequestParams: {
        nonce: number
        identity: CorePrimitivesIdentity
        validation: LitentryValidationData
        networks: Bytes | Vec<Web3Network>
    }[] = []
    const chain = byId['litentry-local']

    const nodeEndpoint: string = chain.rpcs[0].url
    const enclaveEndpoint: string = chain.enclaveRpcs[0].url
    const teeDevNodePort = 9944
    const teeDevWorkerPort = 2000
    const { protocol: workerProtocal, hostname: workerHostname } = new URL(
        enclaveEndpoint
    )
    const { protocol: nodeProtocal, hostname: nodeHostname } = new URL(
        nodeEndpoint
    )
    this.timeout(6000000)

    before(async () => {
        const parachainEndpoint = process.env.PARACHAIN_ENDPOINT
        if (!parachainEndpoint) {
            throw new Error(
                'PARACHAIN_ENDPOINT environment variable is missing.'
            )
        }

        context = await initIntegrationTestContext(
            parachainEndpoint,
            process.env.ENCLAVE_ENDPOINT
        )

        teeShieldingKey = await getTeeShieldingKey(context)
        aliceSubstrateIdentity =
            await context.web3Wallets.substrate.Alice.getIdentity(context)
        alice = genesisSubstrateWallet('Alice')
    })
    async function linkIdentityViaCli(id: string) {
        const credentialDefinitions = credentialsJson.find(
            (item) => item.id === id
        ) as CredentialDefinition
        console.log(`linking identity-${credentialDefinitions.mockDid} via cli`)

        const keyringPair = randomSubstrateWallet()
        keyringPairs.push(keyringPair)
        const formatAddress = u8aToHex(keyringPair.publicKey)
        const substrateIdentity = await new PolkadotSigner(
            keyringPair
        ).getIdentity(context)
        substrateIdentities.push(substrateIdentity)

        try {
            // CLIENT = "$CLIENT_BIN -p $NPORT -P $WORKER1PORT -u $NODEURL -U $WORKER1URL"
            const commandPromise = zx`${clientDir} -p ${teeDevNodePort} -P ${teeDevWorkerPort} -u ${
                nodeProtocal + nodeHostname
            } -U ${workerProtocal + workerHostname}\
                  trusted -d link-identity did:litentry:substrate:${formatAddress}\
                  did:${credentialDefinitions.mockDid}\
                  ${credentialDefinitions.mockWeb3Network}`

            await commandPromise

            //   const idGraphGetter = await createSignedTrustedGetterIdGraph(
            //       context.api,
            //       new PolkadotSigner(keyringPair),
            //       substrateIdentity
            //   )
            //   const res = await sendAesRequestFromGetter(
            //       context,
            //       teeShieldingKey,
            //       hexToU8a(aesKey),
            //       idGraphGetter
            //   )

            //   const idGraph = decodeIdGraph(context.sidechainRegistry, res.value)

            //   assert.lengthOf(idGraph, 2, 'idGraph length should be 2')
        } catch (error: any) {
            console.log(`Exit code: ${error.exitCode}`)
            console.log(`Error: ${error.stderr}`)

            throw error
        }
    }
    // step('loading tokenmapping contract bytecode', async function () {
    //     const file = path.resolve(
    //         './',
    //         '../../artifacts/contracts/token_holding_amount/TokenMapping.sol/TokenMapping.json'
    //     )
    //     const data = fs.readFileSync(file, 'utf8')
    //     contractBytecode = JSON.parse(data).bytecode
    //     assert.isNotEmpty(contractBytecode)
    // })

    // step(
    //     'deploying tokenmapping contract via parachain pallet',
    //     async function () {
    //         const secretValue = 'my-secrets-value'
    //         const secretEncoded = context.api
    //             .createType('String', secretValue)
    //             .toU8a()
    //         const encryptedSecrets = encryptWithTeeShieldingKey(
    //             teeShieldingKey,
    //             secretEncoded
    //         )

    //         const secret = '0x' + encryptedSecrets.toString('hex')

    //         const assertionId = '0x0000000000000000000000000000000000000000'
    //         const createAssertionEventsPromise = subscribeToEvents(
    //             'evmAssertions',
    //             'AssertionCreated',
    //             context.api
    //         )

    //         const proposal = context.api.tx.evmAssertions.createAssertion(
    //             assertionId,
    //             contractBytecode,
    //             [
    //                 // At least three secrets are required here.
    //                 secret,
    //                 secret,
    //                 secret,
    //             ]
    //         )
    //         await context.api.tx.developerCommittee
    //             .execute(proposal, proposal.encodedLength)
    //             .signAndSend(alice)

    //         const event = (await createAssertionEventsPromise).map((e) => e)
    //         assert.equal(event.length, 1)
    //     }
    // )

    // step('requesting VC for deployed contract', async function () {
    //     await sleep(30)
    //     const requestIdentifier = `0x${randomBytes(32).toString('hex')}`
    //     const nonce = (
    //         await getSidechainNonce(context, aliceSubstrateIdentity)
    //     ).toNumber()

    //     const abiCoder = new ethers.utils.AbiCoder()
    //     const encodedData = abiCoder.encode(['string'], ['bnb'])

    //     const assertion = {
    //         dynamic: context.api.createType('DynamicParams', [
    //             Uint8Array.from(
    //                 Buffer.from(
    //                     '0000000000000000000000000000000000000000',
    //                     'hex'
    //                 )
    //             ),
    //             encodedData,
    //             true,
    //         ]),
    //     }

    //     const requestVcCall = await createSignedTrustedCallRequestVc(
    //         context.api,
    //         context.mrEnclave,
    //         context.api.createType('Index', nonce),
    //         context.web3Wallets.substrate.Alice,
    //         aliceSubstrateIdentity,
    //         context.api.createType('Assertion', assertion).toHex(),
    //         context.api.createType('Option<RequestAesKey>', aesKey).toHex(),
    //         requestIdentifier,
    //         {
    //             withWrappedBytes: false,
    //             withPrefix: true,
    //         }
    //     )

    //     const res = await sendRequestFromTrustedCall(
    //         context,
    //         teeShieldingKey,
    //         requestVcCall
    //     )
    //     await assertIsInSidechainBlock(
    //         `${Object.keys(assertion)[0]} requestVcCall`,
    //         res
    //     )
    //     assertVc(context, aliceSubstrateIdentity, res.value)
    // })

    credentialsJson.forEach(({ id }, index) => {
        step(
            `link identity && request vc with all credentials for ${id}`,
            async function () {
                await linkIdentityViaCli(id)
            }
        )
    })
})
