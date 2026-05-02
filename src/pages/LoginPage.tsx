import { useEffect } from 'react'
import { useNavigate, useParams, Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft } from 'lucide-react'
import { toast } from 'react-hot-toast'
import { Input } from '@/components/ui/Input'
import { Button } from '@/components/ui/Button'
import { loginSchema, type LoginInput } from '@/lib/validators'
import { useAuthStore } from '@/store'
import invoiceSyncSvg from '../assets/sync-invoice-logo-blue.svg'

export default function LoginPage() {
  const { role } = useParams<{ role?: string }>()
  const navigate  = useNavigate()
  const { login, isAuthenticated, user } = useAuthStore()

  const isAdmin   = role === 'admin'
  const hasRole   = role === 'admin' || role === 'company'

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated && user) {
      navigate(user.role === 'admin' ? '/admin' : '/company', { replace: true })
    }
  }, [isAuthenticated, user, navigate])

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: hasRole ? {
      email:    isAdmin ? 'admin@tallysync.com' : 'groceries@sharma.com',
      password: isAdmin ? 'admin123' : 'company123',
    } : {},
  })

  const onSubmit = async (data: LoginInput) => {
    try {
      await login(data.email, data.password)
      toast.success('Welcome back!')
      // useEffect on isAuthenticated handles redirect
    } catch {
      toast.error('Invalid email or password')
    }
  }

  const gradientClass = isAdmin
    ? 'bg-gradient-to-br from-gray-950 via-brand-700 to-brand-500'
    : hasRole
      ? 'bg-gradient-to-br from-gray-950 via-teal-700 to-teal-500'
      : 'bg-gradient-to-br from-gray-950 via-gray-800 to-teal-900'

  return (
    <div className={`min-h-screen flex items-center justify-center p-5 ${gradientClass}`}>
      <div className="w-full max-w-md">
        {/* Back link */}
        <Link
          to="/"
          className="inline-flex items-center gap-1.5 text-sm text-white/60 hover:text-white mb-6 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to home
        </Link>

        <div className="card p-10">
          {/* Role badge */}
          {hasRole && (
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold tracking-widest uppercase mb-5 ${isAdmin ? 'bg-brand-50 text-brand-700' : 'bg-teal-50 text-teal-700'}`}>
              {isAdmin ? 'Admin Login' : 'Company Login'}
            </span>
          )}

          {/* Logo */}
          <div className="flex items-center gap-2.5 mb-8">
            <div className={`w-32 h-9 rounded-lg flex items-center justify-center ${isAdmin ? 'bg-brand-500' : ''}`}>
              <img className='w-2xl h-4.5 stroke-white fill-none stroke-2' src={invoiceSyncSvg} alt="InvoiceSync" />
              {/* <svg className="w-5 h-5 stroke-white fill-none stroke-2" viewBox="0 0 24 24">
                <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg> */}
            </div>
            {/* <span className="text-lg font-bold text-gray-900">InvoiceSync</span> */}
             {/* <h1 className="text-2xl font-bold text-gray-700 mb-2">Welcome back</h1> */}
          </div>

         
          <p className="text-xl text-gray-700 mb-7">
            {isAdmin ? 'Sign in to your admin account' : 'Sign in to your company account'}
          </p>

          <form onSubmit={handleSubmit(onSubmit)} noValidate>
            <Input
              {...register('email')}
              label="Email address"
              type="email"
              placeholder={isAdmin ? 'admin@company.com' : 'you@company.com'}
              error={errors.email?.message}
              teal={!isAdmin}
            />
            <Input
              {...register('password')}
              label="Password"
              type="password"
              placeholder="••••••••"
              error={errors.password?.message}
              teal={!isAdmin}
            />

            <Button
              type="submit"
              variant={isAdmin ? 'primary' : 'primary'}
              size="lg"
              loading={isSubmitting}
              className="mt-1"
            >
              Sign in
            </Button>
          </form>

          {hasRole && (
            <p className="text-xs text-gray-500 text-center mt-4">
              Demo: use pre-filled credentials and click Sign in
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
