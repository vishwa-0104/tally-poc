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

  const companyPassword = await bcrypt.hash('company123', 10)

  // Enterprise users (no companyId — all access via UserCompany)
  const sharmaUser = await prisma.user.upsert({
    where: { email: 'sharma@enterprise.com' },
    update: {},
    create: {
      name: 'Sharma Group',
      email: 'sharma@enterprise.com',
      passwordHash: companyPassword,
      role: 'COMPANY',
      enterpriseName: 'Sharma Group',
    },
  })

  const rajUser = await prisma.user.upsert({
    where: { email: 'raj@enterprise.com' },
    update: {},
    create: {
      name: 'Raj Group',
      email: 'raj@enterprise.com',
      passwordHash: companyPassword,
      role: 'COMPANY',
      enterpriseName: 'Raj Group',
    },
  })

  // Companies (no email/user account)
  const sharmaGroceries = await prisma.company.upsert({
    where: { id: 'c1' },
    update: {},
    create: {
      id: 'c1',
      name: 'Sharma Groceries Pvt Ltd',
      gstin: '07AABCS1429B1Z1',
      port: 9000,
      mapping: { purchase: 'Grocery Purchases', cgst: 'Input CGST @2.5%', sgst: 'Input SGST @2.5%', igst: 'Input IGST' },
    },
  })

  const sharmaWholesale = await prisma.company.upsert({
    where: { id: 'c2' },
    update: {},
    create: {
      id: 'c2',
      name: 'Sharma Wholesale',
      gstin: '07AABCS1429B1Z2',
      port: 9001,
    },
  })

  const rajPharma = await prisma.company.upsert({
    where: { id: 'c3' },
    update: {},
    create: {
      id: 'c3',
      name: 'Raj Pharma Store',
      gstin: '09AAACR5055K1Z5',
      port: 9000,
    },
  })

  // UserCompany links
  await prisma.userCompany.upsert({
    where: { userId_companyId: { userId: sharmaUser.id, companyId: sharmaGroceries.id } },
    update: {},
    create: { userId: sharmaUser.id, companyId: sharmaGroceries.id, isDefault: true },
  })

  await prisma.userCompany.upsert({
    where: { userId_companyId: { userId: sharmaUser.id, companyId: sharmaWholesale.id } },
    update: {},
    create: { userId: sharmaUser.id, companyId: sharmaWholesale.id, isDefault: false },
  })

  await prisma.userCompany.upsert({
    where: { userId_companyId: { userId: rajUser.id, companyId: rajPharma.id } },
    update: {},
    create: { userId: rajUser.id, companyId: rajPharma.id, isDefault: true },
  })

  console.log('Seed complete.')
  console.log('Admin login:       admin@tallysync.com / admin123')
  console.log('Enterprise login:  sharma@enterprise.com / company123  (Sharma Groceries + Sharma Wholesale)')
  console.log('Enterprise login:  raj@enterprise.com / company123  (Raj Pharma)')
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
