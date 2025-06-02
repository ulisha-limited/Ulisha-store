// Update the useEffect that fetches product details to add recently viewed functionality
import { useRecentlyViewedStore } from '../store/recentlyViewedStore'

// Inside the ProductDetails component:
const addToRecentlyViewed = useRecentlyViewedStore((state) => state.addProduct)

useEffect(() => {
  if (productId) {
    fetchProductDetails().then(() => {
      if (product) {
        addToRecentlyViewed(product)
      }
    })
  }
}, [productId])