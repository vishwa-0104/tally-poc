import { Navigate } from 'react-router-dom'
import type { ReactNode } from 'react'
import type { Role } from '@/types'
import { useAuthStore } from '@/store'

interface ProtectedRouteProps {
  children: ReactNode
  allowedRole: Role
}

export function ProtectedRoute({ children, allowedRole }: ProtectedRouteProps) {
  const { isAuthenticated, user } = useAuthStore()

  if (!isAuthenticated || !user) {
    return <Navigate to="/" replace />
  }

  if (user.role !== allowedRole) {
    return <Navigate to={user.role === 'admin' ? '/admin' : '/company'} replace />
  }

  return <>{children}</>
}
