# Stage 1: Install dependencies
FROM oven/bun:1.3.7 AS deps
WORKDIR /app
COPY package.json bun.lock turbo.json ./
COPY packages/gitbook/package.json ./packages/gitbook/package.json
COPY packages/browser-types/package.json ./packages/browser-types/package.json
COPY packages/cache-tags/package.json ./packages/cache-tags/package.json
COPY packages/colors/package.json ./packages/colors/package.json
COPY packages/embed/package.json ./packages/embed/package.json
COPY packages/emoji-codepoints/package.json ./packages/emoji-codepoints/package.json
COPY packages/expr/package.json ./packages/expr/package.json
COPY packages/fonts/package.json ./packages/fonts/package.json
COPY packages/icons/package.json ./packages/icons/package.json
COPY packages/openapi-parser/package.json ./packages/openapi-parser/package.json
COPY packages/react-contentkit/package.json ./packages/react-contentkit/package.json
COPY packages/react-math/package.json ./packages/react-math/package.json
COPY packages/react-openapi/package.json ./packages/react-openapi/package.json
COPY patches/ ./patches/
RUN bun install --frozen-lockfile

# Stage 2: Build
FROM oven/bun:1.3.7 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages/*/node_modules ./packages/
COPY . .
# Re-link workspace node_modules after full copy
RUN bun install --frozen-lockfile
ENV GITBOOK_URL=http://localhost:3000
ENV NODE_ENV=production
RUN bun run build

# Stage 3: Production runner
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
