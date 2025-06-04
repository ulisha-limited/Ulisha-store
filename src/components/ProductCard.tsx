import React from 'react';
import { Link } from 'react-router-dom';
import { Heart, Star, Percent } from 'lucide-react';
import { useCurrencyStore } from '../store/currencyStore';
import type { Product } from '../types';

interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  const formatPrice = useCurrencyStore((state) => state.formatPrice);

  return (
    <Link to={`/product/${product.id}`} className="group">
      <div className="relative aspect-square overflow-hidden rounded-lg bg-gray-100">
        <img
          src={product.image}
          alt={product.name}
          className="h-full w-full object-cover object-center transition-transform duration-300 group-hover:scale-105"
        />
        {product.discount_active && product.discount_percentage > 0 && (
          <div className="absolute top-2 left-2 bg-red-500 text-white px-2 py-1 rounded-full flex items-center space-x-1 text-sm">
            <Percent className="w-4 h-4" />
            <span>{product.discount_percentage}% OFF</span>
          </div>
        )}
        <button 
          className="absolute top-2 right-2 p-2 rounded-full bg-white bg-opacity-80 hover:bg-opacity-100 transition-opacity"
          onClick={(e) => {
            e.preventDefault();
            // Wishlist functionality would go here
          }}
        >
          <Heart className="w-5 h-5 text-gray-600" />
        </button>
      </div>
      
      <div className="mt-4 space-y-1">
        <div className="flex items-center space-x-1">
          <Star className="w-4 h-4 text-yellow-400 fill-current" />
          <span className="text-sm text-gray-600">{product.rating?.toFixed(1) || '5.0'}</span>
        </div>
        
        <h3 className="text-sm font-medium text-gray-900 line-clamp-2">
          {product.name}
        </h3>
        
        <div className="flex items-baseline space-x-2">
          <p className="text-base font-bold text-gray-900">
            {formatPrice(product.price)}
          </p>
          {product.discount_active && product.original_price && (
            <p className="text-sm text-gray-500 line-through">
              {formatPrice(product.original_price)}
            </p>
          )}
        </div>
        
        <p className="text-sm text-gray-500">
          Ships from {product.shipping_location}
        </p>
      </div>
    </Link>
  );
}