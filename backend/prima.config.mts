import { defineConfig, env } from 'prisma/config';

export default defineConfig({
    schema: 'prisma/schema.prisma',
    migrations: {
        path: 'prisma/migrations',
    },
    datasource: {
        url: env('DIRECT_URL') || "postgres://postgres.xoecyoghloqojzrqcvrt:kFFRyLMsGDbbRD1X@aws-0-sa-east-1.pooler.supabase.com:5432/postgres",
    },
});
