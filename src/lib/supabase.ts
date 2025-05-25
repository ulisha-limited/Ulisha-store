import { createClient } from '@supabase/supabase-js'
import type { Product } from '../types'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please check your .env file.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
})

// Fallback products for offline/error scenarios
export const fallbackProducts: Product[] = [
  {
    id: '1',
    name: 'Classic White Sneakers',
    description: 'Comfortable and stylish white sneakers for everyday wear',
    price: 15000,
    category: 'Shoes',
    image: 'https://images.unsplash.com/photo-1549298916-b41d501d3772',
    created_at: new Date().toISOString(),
    shipping_location: 'Nigeria',
    rating: 4.5,
  },
  {
    id: '2',
    name: 'Smart Watch Pro',
    description: 'Feature-rich smartwatch with health tracking capabilities',
    price: 25000,
    category: 'Smart Watches',
    image: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a',
    created_at: new Date().toISOString(),
    shipping_location: 'Nigeria',
    rating: 4.8,
  },
  {
    id: '3',
    name: 'Leather Crossbody Bag',
    description: 'Elegant leather crossbody bag for everyday use',
    price: 12000,
    category: 'Handbags',
    image: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa',
    created_at: new Date().toISOString(),
    shipping_location: 'Nigeria',
    rating: 4.3,
  },
]
