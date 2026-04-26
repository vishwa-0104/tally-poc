#!/bin/bash
# Starts postgres in Docker + backend and frontend natively (fixes Docker bridge outbound blocking)

set -e

# Load .env
export $(grep -v '^#' .env | xargs)

echo "Starting postgres in Docker..."
docker-compose up postgres -d

echo "Waiting for postgres to be healthy..."
until docker exec tally-bill-sync-postgres-1 pg_isready -U postgres -q 2>/dev/null; do
  sleep 1
done
echo "Postgres ready."

# Backend env override — connect to postgres on localhost
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/tally_bill_sync"
export JWT_SECRET="${JWT_SECRET:-please-change-this-secret}"
export PORT=3001

echo "Installing backend dependencies if needed..."
cd server && npm install --silent

echo "Pushing DB schema..."
npx prisma db push --skip-generate > /dev/null 2>&1

echo "Seeding DB..."
npm run db:seed > /dev/null 2>&1

echo "Starting backend on :3001..."
npm run dev &
BACKEND_PID=$!

cd ..

echo "Starting frontend on :3000..."
npm run dev &
FRONTEND_PID=$!

echo ""
echo "App running at http://localhost:3000"
echo "Press Ctrl+C to stop all services."

trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; docker-compose stop postgres" EXIT
wait
