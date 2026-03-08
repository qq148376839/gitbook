# Stage 1: Build
FROM node:22-slim AS builder
WORKDIR /app

# Install bun
RUN apt-get update && apt-get install -y curl unzip && \
    curl -fsSL https://bun.sh/install | bash && \
    ln -s /root/.bun/bin/bun /usr/local/bin/bun && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY . .

# Remove patchedDependencies to avoid bun patch bug on older kernels,
# then install, then manually apply patches
RUN node -e " \
  const pkg = require('./package.json'); \
  delete pkg.patchedDependencies; \
  require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2));"
RUN bun install --frozen-lockfile || bun install

# Manually apply patches
RUN cd node_modules/decode-named-character-reference && \
    node -e " \
      const pkg = require('./package.json'); \
      delete pkg.exports['.'].browser; \
      require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2));"

ARG GITBOOK_URL=http://localhost:3000
ENV GITBOOK_URL=${GITBOOK_URL}
ENV NODE_ENV=production
RUN bun run build

# Stage 2: Production runner
FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ARG GITBOOK_URL=http://localhost:3000
ENV GITBOOK_URL=${GITBOOK_URL}

# Copy the Next.js standalone build and static assets
COPY --from=builder /app/packages/gitbook/.next/standalone ./
COPY --from=builder /app/packages/gitbook/.next/static ./packages/gitbook/.next/static
COPY --from=builder /app/packages/gitbook/public ./packages/gitbook/public

EXPOSE 3000
CMD ["node", "packages/gitbook/server.js"]
