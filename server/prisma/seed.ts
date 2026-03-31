import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding database...')

  // Admin user
  const adminPassword = await bcrypt.hash('admin123', 10)
  await prisma.user.upsert({
    where: { email: 'admin@tallysync.com' },
    update: {},
    create: {
      name: 'Admin',
      email: 'admin@tallysync.com',
      passwordHash: adminPassword,
      role: 'ADMIN',
    },
  })

  // Companies + their users
  const companies = [
    {
      id: 'c1',
      name: 'Sharma Groceries Pvt Ltd',
      gstin: '07AABCS1429B1Z1',
      email: 'groceries@sharma.com',
      port: 9000,
      mapping: { purchase: 'Grocery Purchases', cgst: 'Input CGST @2.5%', sgst: 'Input SGST @2.5%', igst: 'Input IGST' },
      userEmail: 'groceries@sharma.com',
      userName: 'Sharma Groceries',
    },
    {
      id: 'c2',
      name: 'Electronics Hub',
      gstin: '27AAFCS5859R1Z4',
      email: 'accounts@ehub.in',
      port: 9000,
      mapping: { purchase: 'Electronics Purchase', cgst: 'Input CGST @9%', sgst: 'Input SGST @9%', igst: 'Input IGST' },
      userEmail: 'accounts@ehub.in',
      userName: 'Electronics Hub',
    },
    {
      id: 'c3',
      name: 'Raj Pharma Store',
      gstin: '09AAACR5055K1Z5',
      email: 'raj@pharmastore.com',
      port: 9000,
      mapping: null,
      userEmail: 'raj@pharmastore.com',
      userName: 'Raj Pharma',
    },
  ]

  for (const c of companies) {
    const company = await prisma.company.upsert({
      where: { id: c.id },
      update: {},
      create: { id: c.id, name: c.name, gstin: c.gstin, email: c.email, port: c.port, mapping: c.mapping ?? undefined },
    })

    const hash = await bcrypt.hash('company123', 10)
    await prisma.user.upsert({
      where: { email: c.userEmail },
      update: {},
      create: {
        name: c.userName,
        email: c.userEmail,
        passwordHash: hash,
        role: 'COMPANY',
        companyId: company.id,
      },
    })
  }

  console.log('Seed complete.')
  console.log('Admin login:   admin@tallysync.com / admin123')
  console.log('Company login: groceries@sharma.com / company123')
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
