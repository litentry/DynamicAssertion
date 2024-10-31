import dotenv from 'dotenv'
import path from 'path'
import { z } from 'zod'

const envSchema = z.object({
    TWITTER_AUTH_TOKEN_V2: z.string(),
    DISCORD_AUTH_TOKEN: z.string(),
    ACHAINABLE_AUTH_KEY: z.string(),
    ONEBLOCK_NOTION_KEY: z.string(),
    NODEREAL_API_KEY: z.string(),
    GENIIDATA_API_KEY: z.string(),
    MORALIS_API_KEY: z.string(),
    MAGIC_CRAFT_API_KEY: z.string(),
})

export type EnvConfig = z.infer<typeof envSchema>

export const loadEnv = (): EnvConfig => {
    const envPath =
        process.env.NODE_ENV === 'local'
            ? path.resolve(process.cwd(), '.env.local')
            : '/opt/worker_configs/worker_env'

    const result = dotenv.config({ path: envPath })

    if (result.error) {
        throw new Error(
            `Failed to load environment variables: ${result.error.message}`
        )
    }

    const parsed = envSchema.safeParse(result.parsed)

    if (!parsed.success) {
        throw new Error(
            `Invalid environment variables: ${parsed.error.message}`
        )
    }

    return parsed.data
}

export const env = loadEnv()
