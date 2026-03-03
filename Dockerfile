# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# Install build dependencies for better-sqlite3
RUN apt-get update && apt-get install -y python3 make g++ 

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM node:20-slim

WORKDIR /app

# Install runtime dependencies for better-sqlite3
RUN apt-get update && apt-get install -y python3 make g++ 

COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.ts ./
# We use tsx to run the server in production too for simplicity in this environment
RUN npm install -g tsx

EXPOSE 4010

# Create a volume for the database
RUN mkdir -p /app/data
VOLUME ["/app/data"]

# Set environment to production
ENV NODE_ENV=production
ENV PORT=4010
ENV DB_PATH=/app/data/data.db

CMD ["tsx", "server.ts"]
