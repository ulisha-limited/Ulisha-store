import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Product } from '../types'

interface RecentlyViewedState {
  products: Product[]
  addProduct: (product: Product) => void
  clearProducts: () => void
}

export const useRecentlyViewedStore = create<RecentlyViewedState>()(
  persist(
    (set) => ({
      products: [],
      addProduct: (product) =>
        set((state) => {
          // Remove the product if it already exists
          const filteredProducts = state.products.filter((p) => p.id !== product.id)
          
          // Add the new product to the beginning of the array
          const newProducts = [product, ...filteredProducts]
          
          // Keep only the last 10 products
          return { products: newProducts.slice(0, 10) }
        }),
      clearProducts: () => set({ products: [] }),
    }),
    {
      name: 'recently-viewed-storage',
    },
  ),
)