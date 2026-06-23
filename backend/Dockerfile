FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

# Data directory for SQLite reports DB — mount a volume here for persistence
RUN mkdir -p /data
ENV DATA_DIR=/data

EXPOSE 3000
CMD ["node", "src/index.js"]
