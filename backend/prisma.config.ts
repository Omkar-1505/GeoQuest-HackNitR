// prisma.config.ts
import "dotenv/config"; // <--- ADD THIS LINE AT THE TOP
import { defineConfig, env } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: {
    url: env("DATABASE_URL"),
  },
  
  migrations: {
    path: "prisma/migrations",
  },// ... rest of your config
});