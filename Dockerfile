# ── Build stage ────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

ARG VITE_CHROME_EXTENSION_ID
ENV VITE_CHROME_EXTENSION_ID=$VITE_CHROME_EXTENSION_ID

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Serve stage ─────────────────────────────────────────────
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80 443
