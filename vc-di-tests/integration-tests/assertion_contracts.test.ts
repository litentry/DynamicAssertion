import { randomBytes, KeyObject } from 'crypto'
import { step } from 'mocha-steps'
import { initIntegrationTestContext } from './common/utils'
import { assertIsInSidechainBlock, assertVc } from './common/utils/assertion'
import {
    getSidechainNonce,
    getTeeShieldingKey,
    sendRequestFromTrustedCall,
    createSignedTrustedCallRequestVc,
    sendAesRequestFromGetter,
    createSignedTrustedGetterIdGraph,
} from './common/di-utils'
import type { IntegrationTestContext } from './common/common-types'
import { aesKey } from './common/call'
import type {
    CorePrimitivesIdentity,
    WorkerRpcReturnValue,
} from '@litentry/parachain-api'
import fs from 'fs'
import path from 'path'
import { assert } from 'chai'
import { genesisSubstrateWallet } from './common/helpers'
import { KeyringPair } from '@polkadot/keyring/types'
import { subscribeToEvents } from './common/transactions'
import {
    encryptWithTeeShieldingKey,
    PolkadotSigner,
} from './common/utils/crypto'
import { ethers } from 'ethers'
import { sleep } from './common/utils'
import { hexToU8a, stringToU8a, u8aToHex } from '@polkadot/util'
import { byId } from '@litentry/chaindata'
import { log, $ as zx } from 'zx'
import { CredentialDefinition, credentialsJson } from './common/credential-json'
import { Keyring } from '@polkadot/keyring'
import { env } from './common/loadEnv'
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
    const substrateIdentities: CorePrimitivesIdentity[] = []
    const keyringPairs: KeyringPair[] = []
    let alice: KeyringPair = undefined as any
    let contractBytecode = undefined as any
    const errorArray: { index: number; assertion: any; error: any }[] = []

    const chain = byId['litentry-dev']
    const nodeEndpoint = chain.rpcs[0].url
    const enclaveEndpoint = chain.enclaveRpcs[0].url
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

    before(async () => {
        console.log(`nodeEndpoint: ${nodeEndpoint}`)
        console.log(`enclaveEndpoint: ${enclaveEndpoint}`)
        context = await initIntegrationTestContext(
            nodeEndpoint,
            enclaveEndpoint
        )

        teeShieldingKey = await getTeeShieldingKey(context)
        alice = genesisSubstrateWallet('Alice')

        contracts = [
            {
                name: 'TokenMapping',
                path: '../../artifacts/contracts/token_holding_amount/TokenMapping.sol/TokenMapping.json',
                secrets: [
                    // The order is very important, refer to the order of secrets(/contracts/token_holding_amount/TokenQueryLogic.sol:queryBalance(...secrets)).
                    generateSecrets(env.GENIIDATA_API_KEY, context),
                    generateSecrets(env.NODEREAL_API_KEY, context),
                    generateSecrets(env.MORALIS_API_KEY, context),
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
    async function requestVc(
        credentialDefinition: CredentialDefinition,
        index: number
    ) {
        try {
            const contractId = matchContractId(
                credentialDefinition.contractName
            )
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

            const asOkResult = await new Promise<any>((resolve, reject) => {
                const onMessageReceived = async (res: WorkerRpcReturnValue) => {
                    try {
                        const vcresponse = context.api.createType(
                            'RequestVcResultOrError',
                            res.value
                        )
                        console.log(
                            `vcresponse len: ${vcresponse.len}, idx: ${
                                vcresponse.idx
                            }, vc result: ${JSON.stringify(vcresponse.result)}`
                        )
                        if (
                            vcresponse.result.isOk &&
                            vcresponse.result.asOk.toString() !== '0x'
                        ) {
                            resolve(vcresponse.result.asOk)
                        }
                    } catch (error) {
                        reject(error)
                    }
                }

                sendRequestFromTrustedCall(
                    context,
                    teeShieldingKey,
                    requestVcCall,
                    onMessageReceived
                ).catch(reject)
            })

            await assertVc(
                context,
                substrateIdentities[index],
                asOkResult,
                credentialDefinition.expectedCredentialValue
            )
        } catch (error) {
            errorArray.push({
                index: index,
                assertion: JSON.stringify(credentialDefinition.name),
                error: error,
            })
            console.error(
                `Error in requestVc for ${credentialDefinition.name} at index ${index}:`,
                error
            )
        }
        await sleep(12)
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
            const commandPromise = zx`docker run --net=host litentry/identity-cli:latest -p ${teeDevNodePort} -P ${teeDevWorkerPort} -u ${
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
            await sendAesRequestFromGetter(
                context,
                teeShieldingKey,
                hexToU8a(aesKey),
                idGraphGetter
            )
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

    credentialsJson.forEach((credentialDefinition, index) => {
        step(
            `linking identity ${credentialDefinition.mockDid} via cli`,
            async function () {
                this.timeout(300000)
                console.log(`index: ${index}`)
                const keyringPair = generateSubstrateAddress(index)
                keyringPairs.push(keyringPair)

                const substrateIdentity = await new PolkadotSigner(
                    keyringPair
                ).getIdentity(context)
                substrateIdentities.push(substrateIdentity)

                await linkIdentityViaCli(credentialDefinition, index)
                await requestVc(credentialDefinition, index)
            }
        )
    })
    after(async function () {
        if (errorArray.length > 0) {
            console.log('errorArray:', errorArray)
            throw new Error(
                `${errorArray.length} tests failed. See above for details.`
            )
        }
    })
})
