# ----------- build stage (installs only prod deps if needed) -----------
FROM node:20-alpine AS base
WORKDIR /app
ENV NODE_ENV=production

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

# ----------- runtime image -----------
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
# If your app uses a different port, update here and in docker run
ENV PORT=3000

# Copy node_modules from build layer, then app source
COPY --from=base /app/node_modules ./node_modules
COPY . .

# (Optional) create a non-root user for better security
RUN addgroup -S appgrp && adduser -S appuser -G appgrp
USER appuser

EXPOSE 4000

# (Optional) basic healthcheck (adjust path if you have /health)
# HEALTHCHECK --interval=30s --timeout=3s \
#   CMD wget -qO- http://localhost:${PORT}/api/student || exit 1

# Prefer npm start (define "start" in package.json)
CMD ["npm", "start"]
