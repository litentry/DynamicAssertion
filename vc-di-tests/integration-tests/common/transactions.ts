import { ApiPromise, FrameSystemEventRecord } from '@litentry/parachain-api'

export const subscribeToEvents = async (
    section: string,
    method: string,
    api: ApiPromise
): Promise<FrameSystemEventRecord[]> => {
    return new Promise<FrameSystemEventRecord[]>((resolve, reject) => {
        let blocksToScan = 15
        const unsubscribe = api.rpc.chain.subscribeNewHeads(
            async (blockHeader) => {
                const shiftedApi = await api.at(blockHeader.hash)

                const allBlockEvents = await shiftedApi.query.system.events()
                const allExtrinsicEvents = allBlockEvents.filter(
                    ({ phase }) => phase.isApplyExtrinsic
                )

                const matchingEvent = allExtrinsicEvents.filter(
                    ({ event, phase }) => {
                        return (
                            event.section === section && event.method === method
                        )
                    }
                )

                if (matchingEvent.length == 0) {
                    blocksToScan -= 1
                    if (blocksToScan < 1) {
                        reject(
                            new Error(
                                `timed out listening for event ${section}.${method}`
                            )
                        )
                        ;(await unsubscribe)()
                    }
                    return
                }

                resolve(matchingEvent)
                ;(await unsubscribe)()
            }
        )
    })
}
