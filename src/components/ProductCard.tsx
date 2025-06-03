// Update the price display to use the currency store
import { useCurrencyStore } from '../store/currencyStore';

// Inside ProductCard component
const formatPrice = useCurrencyStore((state) => state.formatPrice);

// Replace the price formatting with:
<div className="text-base font-bold text-gray-900">
  {formatPrice(product.price)}
</div>
{product.discount_active && formattedOriginalPrice && (
  <div className="text-xs text-gray-500 line-through">
    {formatPrice(product.original_price || 0)}
  </div>
)}