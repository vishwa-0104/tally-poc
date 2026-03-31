#!/bin/sh
set -e

echo "Applying database schema..."
npx prisma db push --skip-generate

echo "Seeding database..."
npm run db:seed || echo "Seed warning (may already be seeded)"

echo "Starting server..."
exec node dist/index.js
