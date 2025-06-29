import React from 'react';
import { useFlutterwave, closePaymentModal } from 'flutterwave-react-v3';
import { useAuthStore } from '../store/authStore';
import type { FlutterwaveConfig } from '../types';

interface FlutterwavePaymentProps {
  amount: number;
  onSuccess: (response: any) => void;
  onClose: () => void;
  onInit?: () => Promise<string | null>;
  customerInfo: {
    name: string;
    email: string;
    phone: string;
  };
  disabled?: boolean;
  className?: string;
  children?: React.ReactNode;
  orderId?: string;
}

export function FlutterwavePayment({
  amount,
  onSuccess,
  onClose,
  onInit,
  customerInfo,
  disabled = false,
  className = '',
  children,
  orderId
}: FlutterwavePaymentProps) {
  const user = useAuthStore((state) => state.user);

  // Generate unique transaction reference
  const generateTxRef = () => {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return `ULISHA_${timestamp}_${random}`;
  };

  const config: FlutterwaveConfig = {
    public_key: 'FLWPUBK-21d59dfb46d1659c3d7e1e09fb312c1a-X',
    tx_ref: orderId ? `ULISHA_${orderId}_${Date.now()}` : generateTxRef(),
    amount: Math.round(amount), // Ensure amount is an integer
    currency: 'NGN',
    payment_options: 'card,mobilemoney,ussd,banktransfer',
    customer: {
      email: customerInfo.email || user?.email || '',
      phone_number: customerInfo.phone || user?.phone || '',
      name: customerInfo.name || user?.user_metadata?.full_name || 'Customer',
    },
    customizations: {
      title: 'Ulisha Store',
      description: 'Payment for items in cart',
      logo: 'https://lgopfgrszxebcoylyocp.supabase.co/storage/v1/object/public/app-assets/ulisha-favicon.png',
    },
    redirect_url: `${window.location.origin}/dashboard?payment_success=true`,
    meta: {
      order_id: orderId || '',
      customer_id: user?.id || '',
      source: 'web'
    }
  };

  const handleFlutterPayment = useFlutterwave(config);

  const handlePayment = async () => {
    if (disabled) return;
    
    try {
      // Validate required fields
      if (!customerInfo.name || !customerInfo.email || !customerInfo.phone) {
        throw new Error('Please fill in all customer information');
      }

      if (amount <= 0) {
        throw new Error('Invalid payment amount');
      }

      // If onInit is provided, call it to get/create the order ID
      let currentOrderId = orderId;
      if (onInit) {
        const newOrderId = await onInit();
        if (!newOrderId) {
          throw new Error('Failed to create order');
        }
        currentOrderId = newOrderId;
      }

      // Update config with the current order ID
      const updatedConfig = {
        ...config,
        tx_ref: currentOrderId ? `ULISHA_${currentOrderId}_${Date.now()}` : generateTxRef(),
        meta: {
          ...config.meta,
          order_id: currentOrderId || ''
        }
      };

      console.log('Initiating Flutterwave payment with config:', {
        tx_ref: updatedConfig.tx_ref,
        amount: updatedConfig.amount,
        currency: updatedConfig.currency,
        customer: updatedConfig.customer,
        order_id: currentOrderId
      });

      handleFlutterPayment({
        callback: (response) => {
          console.log('Flutterwave payment response:', response);
          
          if (response.status === "successful") {
            // Ensure we have the transaction details
            const paymentData = {
              ...response,
              order_id: currentOrderId,
              tx_ref: response.tx_ref || updatedConfig.tx_ref,
              transaction_id: response.transaction_id || response.flw_ref,
              amount: response.amount || amount,
              currency: response.currency || 'NGN'
            };
            
            onSuccess(paymentData);
          } else {
            console.error('Payment failed:', response);
            throw new Error(response.message || 'Payment was not successful');
          }
          closePaymentModal();
        },
        onClose: () => {
          console.log('Payment modal closed');
          onClose();
          closePaymentModal();
        },
      });
    } catch (error) {
      console.error('Error initializing payment:', error);
      
      // Show user-friendly error message
      const errorMessage = error instanceof Error ? error.message : 'Failed to initialize payment';
      
      // Create a temporary notification
      const notification = document.createElement('div');
      notification.className = 'fixed bottom-4 right-4 bg-red-500 text-white px-6 py-3 rounded-lg shadow-lg z-50';
      notification.textContent = errorMessage;
      document.body.appendChild(notification);
      
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 5000);
    }
  };

  return (
    <button
      type="button"
      onClick={handlePayment}
      disabled={disabled}
      className={className}
    >
      {children}
    </button>
  );
}