# Stage 1: Build
FROM oven/bun:1.3.7 AS builder
WORKDIR /app
COPY . .
RUN bun install --frozen-lockfile
ENV GITBOOK_URL=http://localhost:3000
ENV NODE_ENV=production
RUN bun run build

# Stage 2: Production runner
FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV GITBOOK_URL=http://localhost:3000

# Copy the Next.js standalone build and static assets
COPY --from=builder /app/packages/gitbook/.next/standalone ./
COPY --from=builder /app/packages/gitbook/.next/static ./packages/gitbook/.next/static
COPY --from=builder /app/packages/gitbook/public ./packages/gitbook/public

EXPOSE 3000
CMD ["node", "packages/gitbook/server.js"]
