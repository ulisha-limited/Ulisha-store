import React from 'react'
import { Navigate } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

type Role = 'user' | 'admin'

export function ProtectedRoute({
  children,
  requiredRole,
}: {
  children: React.ReactNode
  requiredRole?: Role
}) {
  const user = useAuthStore((state) => state.user)
  const userRole: Role = user?.role === 'admin' ? 'admin' : 'user'

  if (!user) {
    return <Navigate to="/login" />
  }

  if (requiredRole && userRole !== requiredRole) {
    return <Navigate to="/" />
  }

  return <>{children}</>
}
