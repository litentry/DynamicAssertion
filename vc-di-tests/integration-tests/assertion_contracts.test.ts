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
    createSignedTrustedGetterIdGraph,
    decodeIdGraph,
} from './common/di-utils' // @fixme move to a better place
import type { IntegrationTestContext } from './common/common-types'
import { aesKey } from './common/call'
import type {
    CorePrimitivesIdentity,
    LitentryValidationData,
    Web3Network,
    WorkerRpcReturnValue,
} from '@litentry/parachain-api'
import fs from 'fs'
import path from 'path'
import { assert } from 'chai'
import { genesisSubstrateWallet, randomSubstrateWallet } from './common/helpers'
import { KeyringPair } from '@polkadot/keyring/types'
import { subscribeToEvents } from './common/transactions'
import {
    decryptWithAes,
    encryptWithTeeShieldingKey,
    PolkadotSigner,
} from './common/utils/crypto'
import { ethers } from 'ethers'
import { sleep } from './common/utils'
import { Bytes, Vec } from '@polkadot/types-codec'
import { hexToU8a, stringToU8a, u8aToHex } from '@polkadot/util'
import { byId } from '@litentry/chaindata'
import { $ as zx } from 'zx'
import { CredentialDefinition, credentialsJson } from './common/credential-json'
import { Keyring } from '@polkadot/keyring'

function randomContractId(): string {
    const bytes = randomBytes(20)
    return '0x' + bytes.toString('hex')
}

function generateSubstrateAddress(index: number): KeyringPair {
    const keyring = new Keyring({ type: 'sr25519' })

    // generate substrate address from index
    const SEED = `index-${index}`.padEnd(32, ' ')
    return keyring.addFromSeed(stringToU8a(SEED))
}

describe('Test Vc (direct request)', function () {
    let context: IntegrationTestContext = undefined as any
    let teeShieldingKey: KeyObject = undefined as any
    let aliceSubstrateIdentity: CorePrimitivesIdentity = undefined as any
    const substrateIdentities: CorePrimitivesIdentity[] = []
    const keyringPairs: KeyringPair[] = []

    let alice: KeyringPair = undefined as any
    let contractBytecode = undefined as any
    const clientDir = process.env.LITENTRY_CLI_DIR
    const linkIdentityRequestParams: {
        nonce: number
        identity: CorePrimitivesIdentity
        validation: LitentryValidationData
        networks: Bytes | Vec<Web3Network>
    }[] = []
    const chain = byId['litentry-dev']
    const nodeEndpoint: string = chain.rpcs[0].url
    const enclaveEndpoint: string = chain.enclaveRpcs[0].url
    console.log(`[node] ${nodeEndpoint}`)
    console.log(`[worker] ${enclaveEndpoint}`)

    const teeDevNodePort = 443
    const teeDevWorkerPort = 443
    const { protocol: workerProtocal, hostname: workerHostname } = new URL(
        enclaveEndpoint
    )
    const { protocol: nodeProtocal, hostname: nodeHostname } = new URL(
        nodeEndpoint
    )

    this.timeout(6000000)
    interface ContractInfo {
        name: string
        path: string
        secrets: string[]
        bytecode: string
        contractId: string
    }
    let contracts: ContractInfo[]

    function generateSecrets(secret: string, context: IntegrationTestContext) {
        const secretEncoded = context.api.createType('String', secret).toU8a()
        const encryptedSecrets = encryptWithTeeShieldingKey(
            teeShieldingKey,
            secretEncoded
        )
        return '0x' + encryptedSecrets.toString('hex')
    }
    function matchContractId(contractName: string): string {
        const contract = contracts.find(
            (contract) => contract.name === contractName
        )
        if (!contract) {
            throw new Error(`Contract with name ${contractName} not found`)
        }
        return contract.contractId
    }

    async function requestVc(
        credentialDefinition: CredentialDefinition,
        index: number
    ) {
        const contractId = matchContractId(credentialDefinition.contractName)
        console.log(`contractId: ${contractId}`)
        const requestIdentifier = `0x${randomBytes(32).toString('hex')}`
        let currentNonce = (
            await getSidechainNonce(context, substrateIdentities[index])
        ).toNumber()
        const getNextNonce = () => currentNonce++
        const nonce = getNextNonce()

        const abiCoder = new ethers.utils.AbiCoder()
        const encodedData = abiCoder.encode(
            ['string'],
            [credentialDefinition.parameter]
        )
        const assertion = {
            dynamic: context.api.createType('DynamicParams', [
                contractId,
                encodedData,
                true,
            ]),
        }
        const requestVcCall = await createSignedTrustedCallRequestVc(
            context.api,
            context.mrEnclave,
            context.api.createType('Index', nonce),
            new PolkadotSigner(keyringPairs[index]),
            substrateIdentities[index],
            context.api.createType('Assertion', assertion).toHex(),
            context.api.createType('Option<RequestAesKey>', aesKey).toHex(),
            requestIdentifier
        )

        const onMessageReceived = async (res: WorkerRpcReturnValue) => {
            const vcresponse = context.api.createType(
                'RequestVcResultOrError',
                res.value
            )
            console.log(
                `vcresponse len: ${vcresponse.len}, idx: ${
                    vcresponse.idx
                }, vc result: ${JSON.stringify(vcresponse.result)}`
            )
            if (vcresponse.result.isOk)
                await assertVc(
                    context,
                    substrateIdentities[index],
                    vcresponse.result.asOk
                )
            const decryptVcPayload = decryptWithAes(
                aesKey,
                vcresponse.vc_payload,
                'utf-8'
            ).replace('0x', '')
            const vcPayloadJson = JSON.parse(decryptVcPayload)
            console.log(`vcPayloadJson: ${JSON.stringify(vcPayloadJson)}`)
            assert.equal(
                vcPayloadJson.credentialSubject.values[0],
                credentialDefinition.expectedCredentialValue,
                "credential value doesn't match, please check the credential json expectedCredentialValue"
            )
        }
        const callResults = await sendRequestFromTrustedCall(
            context,
            teeShieldingKey,
            requestVcCall,
            onMessageReceived
        )
        await assertIsInSidechainBlock(
            `${Object.keys(assertion)[0]} requestVcCall`,
            callResults
        )
    }
    async function linkIdentityViaCli(
        credentialDefinition: CredentialDefinition,
        index: number
    ) {
        console.log(
            `credentialDefinition: ${JSON.stringify(credentialDefinition)}`
        )
        console.log(`linking identity-${credentialDefinition.mockDid} via cli`)

        const formatAddress = u8aToHex(keyringPairs[index].publicKey)

        try {
            // CLIENT = "$CLIENT_BIN -p $NPORT -P $WORKER1PORT -u $NODEURL -U $WORKER1URL"
            const commandPromise = zx`docker run litentry/identity-cli:latest -p ${teeDevNodePort} -P ${teeDevWorkerPort} -u ${
                nodeProtocal + nodeHostname
            } -U ${workerProtocal + workerHostname}\
                  trusted -d link-identity did:litentry:substrate:${formatAddress}\
                  did:${credentialDefinition.mockDid}\
                  ${credentialDefinition.mockWeb3Network}`

            await commandPromise

            const idGraphGetter = await createSignedTrustedGetterIdGraph(
                context.api,
                new PolkadotSigner(keyringPairs[index]),
                substrateIdentities[index]
            )
            const res = await sendAesRequestFromGetter(
                context,
                teeShieldingKey,
                hexToU8a(aesKey),
                idGraphGetter
            )

            const idGraph = decodeIdGraph(context.sidechainRegistry, res.value)

            assert.lengthOf(idGraph, 2, 'idGraph length should be 2')
        } catch (error: any) {
            if (
                error.stderr &&
                error.stderr.includes(
                    'LinkIdentityFailed(StfError(IdentityAlreadyLinked))'
                )
            ) {
                console.log('Identity already linked, continuing execution...')
            } else {
                console.log(`Exit code: ${error.exitCode}`)
                console.log(`Error: ${error.stderr}`)
                throw error
            }
        }
    }
    before(async () => {
        const parachainEndpoint = process.env.PARACHAIN_ENDPOINT
        if (!parachainEndpoint) {
            throw new Error(
                'PARACHAIN_ENDPOINT environment variable is missing.'
            )
        }

        context = await initIntegrationTestContext(
            nodeEndpoint,
            enclaveEndpoint
        )

        teeShieldingKey = await getTeeShieldingKey(context)
        aliceSubstrateIdentity =
            await context.web3Wallets.substrate.Alice.getIdentity(context)
        alice = genesisSubstrateWallet('Alice')

        contracts = [
            {
                name: 'TokenMapping',
                path: '../../artifacts/contracts/token_holding_amount/TokenMapping.sol/TokenMapping.json',
                secrets: [
                    // The order is very important, refer to the order of secrets(/contracts/token_holding_amount/TokenQueryLogic.sol:queryBalance(...secrets)).
                    generateSecrets(process.env.GENIIDATA_API_KEY!, context),
                    generateSecrets(process.env.NODEREAL_API_KEY!, context),
                    generateSecrets(process.env.MORALIS_API_KEY!, context),
                ],
                bytecode: '',
                contractId: randomContractId(),
            },
            {
                name: 'PlatformUser',
                path: '../../artifacts/contracts/platform_user/PlatformUser.sol/PlatformUser.json',
                secrets: [],
                bytecode: '',
                contractId: randomContractId(),
            },
            // add more contracts here
        ]
    })

    step('loading contract bytecode', async function () {
        for (const contract of contracts) {
            const file = path.resolve('./', contract.path)
            const data = fs.readFileSync(file, 'utf8')
            contractBytecode = JSON.parse(data).bytecode
            console.log(`contractBytecode: ${contractBytecode.length}`)
            const truncatedBytecode =
                contractBytecode.slice(0, 100) +
                '......' +
                contractBytecode.slice(contractBytecode.length - 100)
            console.log(
                `contract name: ${contract.name} contract Bytecode: ${truncatedBytecode}`
            )
            assert.isNotEmpty(
                contractBytecode,
                `contractBytecode is empty for ${contract.name}`
            )
            contract.bytecode = contractBytecode
        }
    })

    step('deploying contract via parachain pallet', async function () {
        for (const contract of contracts) {
            const { contractId } = contract
            const createAssertionEventsPromise = subscribeToEvents(
                'evmAssertions',
                'AssertionCreated',
                context.api
            )
            const proposal = context.api.tx.evmAssertions.createAssertion(
                contractId,
                contract.bytecode,
                contract.secrets
            )
            await context.api.tx.developerCommittee
                .execute(proposal, proposal.encodedLength)
                .signAndSend(alice)

            const event = (await createAssertionEventsPromise).map((e) => e)
            assert.equal(
                event.length,
                1,
                `event length should be 1 for ${contract.name}`
            )

            console.log(
                `deployed success ✅ contract name: ${contract.name} contract Id: ${contractId}`
            )
        }
        await sleep(12)
    })

 for (const [index, credentialDefinition] of credentialsJson.entries()) {
     step(
         `linking identity ${credentialDefinition.mockDid} via cli`,
         async function () {
             const keyringPair = generateSubstrateAddress(
                 credentialDefinition.index
             )
             keyringPairs.push(keyringPair)

             const substrateIdentity = await new PolkadotSigner(
                 keyringPair
             ).getIdentity(context)
             substrateIdentities.push(substrateIdentity)

             await linkIdentityViaCli(credentialDefinition, index)
             await requestVc(credentialDefinition, index)
             console.log('waiting 12 seconds...')

             await sleep(12)
         }
     )
 }
})
