import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Mail, Lock, User, ShoppingBag } from 'lucide-react'
import { useAuthStore } from '../../store/authStore'
import { PasswordStrengthMeter } from '../../components/PasswordStrengthMeter'

export function Register() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [passwordStrength, setPasswordStrength] = useState(0)

  const navigate = useNavigate()
  const signUp = useAuthStore((state) => state.signUp)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    // Validate passwords match
    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }

    // Check password strength
    if (passwordStrength < 3) {
      setError('Please choose a stronger password')
      return
    }

    setLoading(true)

    try {
      await signUp(email, password, name)
      navigate('/dashboard')
    } catch (err: any) {
      setError(err.message || 'An error occurred during registration')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[calc(100vh-4rem)] bg-white flex flex-col justify-center py-8 sm:py-12 px-4 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center mb-6">
          <ShoppingBag className="h-12 w-12 text-primary-orange" />
        </div>
        <h2 className="text-2xl sm:text-3xl text-center font-extrabold text-gray-900 mb-2">
          Create your UlishaStore account
        </h2>
        <p className="text-center text-gray-600">Join our community today</p>
        <p className="text-center text-primary-orange font-medium mt-2">
          Enjoy up to 20% discounts on all products!
        </p>
      </div>

      <div className="mt-8 sm:mx-auto w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 sm:px-10 shadow-xl rounded-lg border border-gray-200">
          {error && (
            <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
              {error}
            </div>
          )}

          <form className="space-y-6" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                Full Name
              </label>
              <div className="mt-1 relative">
                <input
                  id="name"
                  type="text"
                  required
                  className="pl-10 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-orange focus:ring-primary-orange"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
                <User className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              </div>
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <div className="mt-1 relative">
                <input
                  id="email"
                  type="email"
                  required
                  className="pl-10 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-orange focus:ring-primary-orange"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
                <Mail className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div className="mt-1 relative">
                <input
                  id="password"
                  type="password"
                  required
                  className="pl-10 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-primary-orange focus:ring-primary-orange"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
                <Lock className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              </div>
              <PasswordStrengthMeter password={password} onStrengthChange={setPasswordStrength} />
            </div>

            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <div className="mt-1 relative">
                <input
                  id="confirmPassword"
                  type="password"
                  required
                  className={`pl-10 block w-full rounded-md border ${
                    confirmPassword && password !== confirmPassword
                      ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                      : 'border-gray-300 focus:border-primary-orange focus:ring-primary-orange'
                  } px-3 py-2 shadow-sm`}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
                <Lock className="h-5 w-5 text-gray-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
              </div>
              {confirmPassword && password !== confirmPassword && (
                <p className="mt-1 text-sm text-red-600">Passwords do not match</p>
              )}
            </div>

            <div className="flex items-center">
              <input
                id="terms"
                name="terms"
                type="checkbox"
                required
                className="h-4 w-4 text-primary-orange focus:ring-primary-orange border-gray-300 rounded"
              />
              <label htmlFor="terms" className="ml-2 block text-sm text-gray-700">
                I agree to the{' '}
                <a href="#" className="text-primary-orange hover:text-primary-orange/90">
                  Terms of Service
                </a>{' '}
                and{' '}
                <a href="#" className="text-primary-orange hover:text-primary-orange/90">
                  Privacy Policy
                </a>
              </label>
            </div>

            <button
              type="submit"
              disabled={loading || password !== confirmPassword || passwordStrength < 3}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-orange hover:bg-primary-orange/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-orange transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Creating account...' : 'Create Account'}
            </button>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-gray-500">
                  Already have an account?{' '}
                  <Link to="/login" className="text-primary-orange hover:text-primary-orange/90">
                    Sign in
                  </Link>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
