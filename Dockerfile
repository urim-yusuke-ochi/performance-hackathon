# Build stage
FROM node:22.14.0-slim AS builder

WORKDIR /app

# Enable corepack for pnpm
RUN corepack enable pnpm

# Copy workspace configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY patches ./patches/

# Copy workspace package.json files
COPY workspaces/configs/package.json ./workspaces/configs/
COPY workspaces/schema/package.json ./workspaces/schema/
COPY workspaces/client/package.json ./workspaces/client/
COPY workspaces/server/package.json ./workspaces/server/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY workspaces/configs ./workspaces/configs/
COPY workspaces/schema ./workspaces/schema/
COPY workspaces/client ./workspaces/client/
COPY workspaces/server ./workspaces/server/
COPY public ./public/
COPY prettier.config.mjs ./

# Build client
RUN pnpm run build

# Production stage
FROM node:22.14.0-slim AS production

WORKDIR /app

RUN corepack enable pnpm

# Copy workspace configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY patches ./patches/

# Copy workspace package.json files
COPY workspaces/configs/package.json ./workspaces/configs/
COPY workspaces/schema/package.json ./workspaces/schema/
COPY workspaces/client/package.json ./workspaces/client/
COPY workspaces/server/package.json ./workspaces/server/

# Install dependencies (including dev - needed for SSR with tsx)
RUN pnpm install --frozen-lockfile

# Copy built client assets from builder
COPY --from=builder /app/workspaces/client/dist ./workspaces/client/dist/

# Copy all source (needed for SSR - server uses tsx to run TypeScript directly)
COPY workspaces/client ./workspaces/client/
COPY workspaces/server ./workspaces/server/
COPY workspaces/schema ./workspaces/schema/
COPY workspaces/configs ./workspaces/configs/
COPY public ./public/

# Expose port
ENV PORT=8000
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:8000/').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

# Start server
CMD ["pnpm", "run", "heroku-start"]