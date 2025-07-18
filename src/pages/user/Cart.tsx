import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  Trash2,
  Minus,
  Plus,
  CreditCard,
  ShoppingBag,
  Loader,
  Truck,
  MessageCircle,
  Info,
  AlertCircle,
} from "lucide-react";
import { useCartStore } from "../../store/cartStore";
import { useAuthStore } from "../../store/authStore";
import { useCurrencyStore } from "../../store/currencyStore";
import { FlutterwavePayment } from "../../components/FlutterwavePayment";
import { OrderReceipt } from "../../components/OrderReceipt";
import { supabase } from "../../lib/supabase";

const DELIVERY_FEE = 4000; // ₦4,000
const FREE_DELIVERY_THRESHOLD = 50000; // ₦50,000

// Define a type for your address structure from 'user_addresses' table
interface UserAddress {
  id: string;
  user_id: string;
  full_name: string;
  phone_number: string;
  street_address: string;
  city: string;
  state_province: string;
  // Add any other address fields you have, e.g., 'zip_code', 'country'
}

export default function Cart() {
  const {
    items,
    removeFromCart,
    updateQuantity,
    loading: cartLoading,
    fetchCart,
    clearCart,
  } = useCartStore();
  const user = useAuthStore((state) => state.user);
  const { formatPrice, currency } = useCurrencyStore();
  const navigate = useNavigate();
  const [checkoutLoading, setCheckoutLoading] = useState(false);
  const [showReceipt, setShowReceipt] = useState(false);
  const [currentOrder, setCurrentOrder] = useState<any>(null);
  const [orderId, setOrderId] = useState<string | null>(null);
  const [paymentOption, setPaymentOption] = useState<"full" | "partial">(
    "full"
  );
  const [error, setError] = useState<string | null>(null);
  const [userAddresses, setUserAddresses] = useState<UserAddress[]>([]);
  const [selectedAddressId, setSelectedAddressId] = useState<string | null>(
    null
  );

  const canCheckout = items.length >= 2; // Minimum 2 items required for checkout

  // Delivery details state - now derived from selectedAddress
  const [deliveryDetails, setDeliveryDetails] = useState({
    name: "",
    phone: "",
    address: "", // Combines street_address, city
    state: "", // Holds state_province
  });

  // Fetch cart and user addresses on component mount or user change
  useEffect(() => {
    if (user) {
      fetchCart();
      fetchUserAddresses();
    }
  }, [user, fetchCart]);

  // Update deliveryDetails when selectedAddressId or userAddresses change
  useEffect(() => {
    const selectedAddress = userAddresses.find(
      (address) => address.id === selectedAddressId
    );
    if (selectedAddress) {
      setDeliveryDetails({
        name: selectedAddress.full_name,
        phone: selectedAddress.phone_number,
        address: `${selectedAddress.street_address}, ${selectedAddress.city}`,
        state: selectedAddress.state_province,
      });
    } else {
      // Clear delivery details if no address is selected or found
      setDeliveryDetails({
        name: "",
        phone: "",
        address: "",
        state: "",
      });
    }
  }, [selectedAddressId, userAddresses]);

  // Handle payment success redirect from Flutterwave
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const paymentSuccess = urlParams.get("payment_success");

    if (paymentSuccess === "true") {
      // Clear the URL parameters to prevent re-triggering on refresh
      window.history.replaceState({}, document.title, window.location.pathname);

      clearCart().catch((err) => console.error("Error clearing cart:", err));

      showNotification(
        "Payment successful! Your order has been placed.",
        "success"
      );
      navigate("/dashboard"); // Redirect to a success page or dashboard
    }
  }, [navigate, clearCart]);

  // Listen for currency changes (if this is a custom event)
  useEffect(() => {
    const handleCurrencyChange = () => {
      // Force re-render by updating a state (e.g., re-evaluating price displays)
      setCheckoutLoading(false); // A simple way to trigger re-render
    };

    window.addEventListener("currencyChange", handleCurrencyChange);
    return () =>
      window.removeEventListener("currencyChange", handleCurrencyChange);
  }, []);

  const fetchUserAddresses = useCallback(async () => {
    if (!user?.id) {
      setUserAddresses([]);
      return;
    }
    try {
      const { data, error } = await supabase
        .from("user_addresses") // Ensure this table exists and has 'user_id', 'full_name', 'phone_number', 'street_address', 'city', 'state_province'
        .select("*")
        .eq("user_id", user.id);

      if (error) {
        throw error;
      }

      setUserAddresses(data || []);
      // Automatically select the first address if available and none is selected yet
      if (data && data.length > 0 && !selectedAddressId) {
        setSelectedAddressId(data[0].id);
      }
    } catch (error: any) {
      console.error("Error fetching user addresses:", error.message);
      setError("Failed to load your addresses. Please try again.");
    }
  }, [user, selectedAddressId]); // Added selectedAddressId to dependencies to avoid stale closure if it changes externally

  const subtotal = items.reduce((sum, item) => {
    if (item.product) {
      return sum + item.product.price * item.quantity;
    }
    return 0; // Return 0 for items without a product to prevent NaN
  }, 0);

  const deliveryFee = subtotal >= FREE_DELIVERY_THRESHOLD ? 0 : DELIVERY_FEE;

  const getPaymentAmount = useCallback(() => {
    if (paymentOption === "partial") {
      return subtotal;
    }
    return subtotal + deliveryFee;
  }, [paymentOption, subtotal, deliveryFee]);

  const total = subtotal + deliveryFee;
  const paymentAmount = getPaymentAmount();

  const handleQuantityChange = async (
    productId: string,
    newQuantity: number
  ) => {
    if (newQuantity < 1) return;
    try {
      await updateQuantity(productId, newQuantity);
    } catch (error) {
      console.error("Error updating quantity:", error);
      showNotification("Failed to update quantity.", "error");
    }
  };

  const handleRemoveItem = async (productId: string) => {
    try {
      await removeFromCart(productId);
    } catch (error) {
      console.error("Error removing item:", error);
      showNotification("Failed to remove item from cart.", "error");
    }
  };

  const createOrder = async () => {
    try {
      setError(null);

      if (
        !selectedAddressId ||
        !deliveryDetails.name ||
        !deliveryDetails.phone ||
        !deliveryDetails.address ||
        !deliveryDetails.state
      ) {
        throw new Error("Please select a valid delivery address to proceed.");
      }

      if (items.length === 0) {
        throw new Error(
          "Your cart is empty. Please add items before checking out."
        );
      }

      if (!user?.id) {
        throw new Error("User not authenticated. Please log in.");
      }

      const cartItems = items.map((item) => ({
        product_id: item.product_id,
        quantity: item.quantity,
        price: item.product.price,
        variant_id: item.variant_id || null,
        selected_color: item.selected_color || null,
        selected_size: item.selected_size || null,
      }));

      const { data: newOrderId, error: orderError } = await supabase.rpc(
        "create_order_with_items", // Ensure this Supabase function exists and is up-to-date
        {
          p_user_id: user.id,
          p_total: total,
          p_delivery_fee: deliveryFee,
          p_delivery_fee_paid: paymentOption === "full",
          p_payment_option: paymentOption,
          p_delivery_name: deliveryDetails.name,
          p_delivery_phone: deliveryDetails.phone,
          p_delivery_address: `${deliveryDetails.address}, ${deliveryDetails.state}`,
          p_payment_method: "flutterwave", // This should probably be dynamic or set after successful payment
          p_cart_items: JSON.stringify(cartItems),
        }
      );

      if (orderError) {
        console.error("Supabase Order creation error:", orderError);
        throw new Error(`Failed to create order: ${orderError.message}`);
      }

      if (!newOrderId) {
        throw new Error(
          "Order creation failed - no order ID returned from Supabase."
        );
      }

      return newOrderId;
    } catch (error: any) {
      console.error("Error in createOrder:", error);
      setError(error.message);
      throw error;
    }
  };

  const handleFlutterwaveInit = async () => {
    setCheckoutLoading(true);
    setError(null);
    try {
      const newOrderId = await createOrder();
      setOrderId(newOrderId);
      return newOrderId; // Flutterwave component expects this
    } catch (err: any) {
      // Error already set by createOrder
      setCheckoutLoading(false);
      return null;
    }
  };

  const handleFlutterwaveSuccess = async (response: any) => {
    try {
      setError(null);
      if (!orderId) {
        throw new Error("Order ID missing for payment update.");
      }

      const { data: updatedOrder, error: updateError } = await supabase
        .from("orders")
        .update({
          payment_ref:
            response.transaction_id || response.tx_ref || response.flw_ref,
          status: "completed", // Or 'processing', depending on your workflow
        })
        .eq("id", orderId)
        .select(
          `
          *,
          items:order_items (
            id,
            product:products (
              name,
              image
            ),
            quantity,
            price
          )
          `
        )
        .single();

      if (updateError) {
        console.error("Error updating order after payment:", updateError);
        throw updateError;
      }

      setCurrentOrder(updatedOrder);
      setShowReceipt(true);

      const whatsappMessage = generateWhatsAppMessage(updatedOrder, items);
      window.open(
        `https://wa.me/2347060438205?text=${encodeURIComponent(
          whatsappMessage
        )}`,
        "_blank"
      );

      await clearCart();
      showNotification(
        "Order placed successfully! You can now download your receipt.",
        "success"
      );
    } catch (error: any) {
      console.error(
        "Error processing order after successful payment callback:",
        error
      );
      setError(
        "Payment was successful, but there was an error processing your order. Please contact support."
      );
      showNotification(
        "Payment was successful, but there was an error processing your order. Please contact support.",
        "error"
      );
    } finally {
      setCheckoutLoading(false);
      setOrderId(null); // Clear orderId to prevent re-deletion on subsequent closes
    }
  };

  const handleFlutterwaveClose = useCallback(() => {
    setCheckoutLoading(false);
    // If payment was cancelled, delete the pending order created by handleFlutterwaveInit
    if (orderId) {
      supabase
        .from("orders")
        .delete()
        .eq("id", orderId)
        .then(
          () => {
            setOrderId(null);
            console.log("Pending order deleted due to payment close.");
          },
          (error: any) => {
            console.error("Error deleting pending order:", error.message);
          }
        );
    }
  }, [orderId]); // Dependency on orderId to ensure it's up-to-date

  const generateWhatsAppMessage = (order: any, currentCartItems: any[]) => {
    const formattedTotal = formatPrice(order.total);
    const formattedPaymentAmount = formatPrice(paymentAmount);
    const formattedDeliveryFee = formatPrice(deliveryFee);

    let message = `🛍️ *New Order #${order.id.substring(0, 8)}*\n\n`;
    message += `*Customer Details:*\n`;
    message += `Name: ${order.delivery_name}\n`;
    message += `Phone: ${order.delivery_phone}\n`;
    message += `Address: ${order.delivery_address}\n\n`;

    message += `*Order Items:*\n`;
    // Use currentCartItems (from CartStore) for detailed product info
    currentCartItems.forEach((item) => {
      const itemSubtotal = formatPrice(item.quantity * item.product.price);
      let itemDetails = `• ${item.product.name} (×${item.quantity}) - ${itemSubtotal}`;
      if (item.selected_color)
        itemDetails += ` (Color: ${item.selected_color})`;
      if (item.selected_size) itemDetails += ` (Size: ${item.selected_size})`;
      message += `${itemDetails}\n`;
    });

    message += `\n*Payment Details:*\n`;
    message += `Subtotal: ${formatPrice(subtotal)}\n`;

    if (deliveryFee > 0) {
      message += `Delivery Fee: ${formattedDeliveryFee}`;
      if (paymentOption === "partial") {
        message += ` (To be paid on arrival)\n`;
      } else {
        message += ` (Paid online)\n`;
      }
    } else {
      message += `Delivery Fee: FREE\n`;
    }

    message += `*Total Order Value:* ${formattedTotal}\n`;
    message += `*Amount Paid Online:* ${formattedPaymentAmount}\n`;

    if (paymentOption === "partial" && deliveryFee > 0) {
      message += `*Amount to Collect on Delivery:* ${formattedDeliveryFee}\n`;
    }

    message += `*Payment Method:* Online Payment (Flutterwave)\n`; // Fixed payment method for clarity
    message += `*Payment Reference:* ${order.payment_ref || "N/A"}\n\n`;
    message += `Please process my order. Thank you!`;

    return message;
  };

  const handleChatWithSales = () => {
    const message =
      "Hello! I'm interested in making a purchase from Ulisha Store. Can you help me?";
    window.open(
      `https://wa.me/2347060438205?text=${encodeURIComponent(message)}`,
      "_blank"
    );
  };

  // Only "success" and "error" are allowed for type
  const showNotification = (message: string, type: "success" | "error") => {
    const notification = document.createElement("div");
    notification.className = `fixed bottom-4 right-4 ${
      type === "success" ? "bg-green-500" : "bg-red-500"
    } text-white px-6 py-3 rounded-lg shadow-lg z-50 animate-fade-in`;
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
      notification.classList.add("animate-fade-out");
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 3000);
  };

  if (cartLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader className="h-8 w-8 animate-spin text-primary-orange" />
      </div>
    );
  }

  if (!items.length) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <ShoppingBag className="h-16 w-16 text-gray-400 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Your cart is empty
          </h2>
          <p className="text-gray-600 mb-4">
            Add some items to your cart to get started
          </p>
          <button
            onClick={() => navigate("/")}
            className="text-primary-orange hover:text-primary-orange/90 font-medium"
          >
            Continue Shopping
          </button>
        </div>
      </div>
    );
  }

  // Determine if checkout buttons should be disabled
  const isCheckoutDisabled =
    !selectedAddressId ||
    checkoutLoading ||
    !canCheckout ||
    userAddresses.length === 0 ||
    paymentAmount <= 0; // Disable if amount to pay is 0 (e.g., all free delivery and partial payment)

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Cart items */}
          <div className="lg:col-span-8">
            <div className="bg-white rounded-lg shadow-md">
              <div className="p-6">
                <div className="flex justify-between items-center mb-6">
                  <h2 className="text-2xl font-bold text-gray-900">
                    Shopping Cart
                  </h2>
                  <button
                    onClick={handleChatWithSales}
                    className="flex items-center space-x-2 bg-green-500 text-white px-4 py-2 rounded-lg hover:bg-green-600 transition-colors"
                  >
                    <MessageCircle className="w-5 h-5" />
                    <span>Chat with Sales</span>
                  </button>
                </div>

                {/* Error Display */}
                {error && (
                  <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                    <div className="flex items-center">
                      <AlertCircle className="w-5 h-5 text-red-600 mr-2" />
                      <p className="text-red-800 text-sm">{error}</p>
                    </div>
                  </div>
                )}

                <div className="space-y-4">
                  {items.map((item) => {
                    if (!item.product) return null;

                    return (
                      <div
                        key={item.id}
                        className="flex flex-col sm:flex-row justify-between border-b pb-4"
                      >
                        <div className="flex items-center space-x-4">
                          <img
                            src={item.product.image}
                            alt={item.product.name}
                            className="w-20 h-20 object-cover rounded-md"
                          />
                          <div>
                            <h3 className="text-sm font-medium text-gray-900">
                              {item.product.name}
                            </h3>
                            <p className="text-sm text-gray-500">
                              {item.product.category}
                            </p>
                            {/* Display selected variant details */}
                            {(item.selected_color || item.selected_size) && (
                              <div className="text-sm text-gray-600 mt-1">
                                {item.selected_color && (
                                  <span className="mr-2">
                                    Color: {item.selected_color}
                                  </span>
                                )}
                                {item.selected_size && (
                                  <span>Size: {item.selected_size}</span>
                                )}
                              </div>
                            )}
                            <p className="text-lg font-bold text-gray-900 mt-1">
                              {formatPrice(item.product.price)}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-4 self-center sm:self-auto mt-4 sm:mt-0">
                          <div className="flex items-center space-x-2">
                            <button
                              onClick={() =>
                                handleQuantityChange(
                                  item.product_id,
                                  item.quantity - 1
                                )
                              }
                              className="p-1 rounded-full hover:bg-gray-100 disabled:opacity-50"
                              disabled={cartLoading || item.quantity <= 1}
                            >
                              <Minus className="w-4 h-4" />
                            </button>
                            <span className="w-8 text-center">
                              {item.quantity}
                            </span>
                            <button
                              onClick={() =>
                                handleQuantityChange(
                                  item.product_id,
                                  item.quantity + 1
                                )
                              }
                              className="p-1 rounded-full hover:bg-gray-100 disabled:opacity-50"
                              disabled={cartLoading}
                            >
                              <Plus className="w-4 h-4" />
                            </button>
                          </div>
                          <button
                            onClick={() => handleRemoveItem(item.product_id)}
                            className="text-red-500 hover:text-red-600 disabled:opacity-50"
                            disabled={cartLoading}
                          >
                            <Trash2 className="w-5 h-5" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>

          {/* Order summary and delivery details */}
          <div className="lg:col-span-4">
            <div className="bg-white rounded-lg shadow-md p-6 sticky top-4">
              <h2 className="text-lg font-bold text-gray-900 mb-4">
                Order Summary
              </h2>
              <div className="space-y-4 mb-6">
                <div className="flex justify-between">
                  <span>Subtotal ({items.length} items)</span>
                  <span>{formatPrice(subtotal)}</span>
                </div>

                {/* Delivery Information */}
                <div className="border-t pt-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center">
                      <Truck className="h-5 w-5 text-gray-400 mr-2" />
                      <span className="text-sm font-medium text-gray-900">
                        Delivery Fee
                      </span>
                    </div>
                    <span className="text-sm">
                      {deliveryFee === 0 ? (
                        <span className="text-green-600 font-medium">FREE</span>
                      ) : (
                        formatPrice(deliveryFee)
                      )}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500">
                    {subtotal >= FREE_DELIVERY_THRESHOLD
                      ? "You've qualified for free delivery!"
                      : `Add ${formatPrice(
                          FREE_DELIVERY_THRESHOLD - subtotal
                        )} more to get free delivery`}
                  </p>
                </div>

                {/* Payment Options */}
                {deliveryFee > 0 && (
                  <div className="border-t pt-4">
                    <h3 className="text-sm font-medium text-gray-900 mb-3 flex items-center">
                      <Info className="w-4 h-4 mr-2 text-blue-500" />
                      Payment Options
                    </h3>
                    <div className="space-y-3">
                      <label className="flex items-start space-x-3 p-3 border rounded-lg hover:bg-gray-50 cursor-pointer">
                        <input
                          type="radio"
                          name="paymentOption"
                          value="full"
                          checked={paymentOption === "full"}
                          onChange={(e) =>
                            setPaymentOption(
                              e.target.value as "full" | "partial"
                            )
                          }
                          className="h-4 w-4 text-primary-orange focus:ring-primary-orange border-gray-300 mt-0.5"
                        />
                        <div className="flex-1">
                          <span className="text-sm font-medium text-gray-900">
                            Pay Full Amount Online
                          </span>
                          <div className="text-sm text-gray-600">
                            {formatPrice(total)} - Everything paid upfront
                          </div>
                        </div>
                      </label>

                      <label className="flex items-start space-x-3 p-3 border rounded-lg hover:bg-gray-50 cursor-pointer">
                        <input
                          type="radio"
                          name="paymentOption"
                          value="partial"
                          checked={paymentOption === "partial"}
                          onChange={(e) =>
                            setPaymentOption(
                              e.target.value as "full" | "partial"
                            )
                          }
                          className="h-4 w-4 text-primary-orange focus:ring-primary-orange border-gray-300 mt-0.5"
                        />
                        <div className="flex-1">
                          <span className="text-sm font-medium text-gray-900">
                            Pay Products Only
                          </span>
                          <div className="text-sm text-gray-600">
                            {formatPrice(subtotal)} now +{" "}
                            {formatPrice(deliveryFee)} on delivery
                          </div>
                        </div>
                      </label>
                    </div>

                    {paymentOption === "partial" && (
                      <div className="mt-3 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
                        <div className="flex items-start">
                          <Info className="w-4 h-4 text-yellow-600 mt-0.5 mr-2" />
                          <p className="text-xs text-yellow-800">
                            <strong>Note:</strong> You'll pay{" "}
                            {formatPrice(deliveryFee)} to the delivery person
                            upon arrival.
                          </p>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                <div className="text-xs text-gray-700 bg-blue-50 p-3 rounded-md">
                  <div className="flex items-start">
                    <Truck className="w-4 h-4 text-blue-600 mt-0.5 mr-2" />
                    <div>
                      <p className="font-medium text-blue-900 mb-1">
                        Delivery Information
                      </p>
                      <p>
                        Delivery takes 1-14 days after payment confirmation.
                        We'll call you to confirm delivery details before
                        shipping.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="border-t pt-4">
                  <div className="flex justify-between font-bold text-lg">
                    <span>Amount to Pay Now</span>
                    <span className="text-primary-orange">
                      {formatPrice(paymentAmount)}
                    </span>
                  </div>
                  {paymentOption === "partial" && deliveryFee > 0 && (
                    <div className="flex justify-between text-sm text-gray-600 mt-1">
                      <span>Pay on delivery</span>
                      <span>{formatPrice(deliveryFee)}</span>
                    </div>
                  )}
                </div>
                {currency === "USD" && (
                  <p className="text-xs text-gray-500 mt-1">
                    Converted from NGN at rate: 1 USD = ₦1,630
                  </p>
                )}
              </div>

              {/* Delivery Address Selection */}
              <div>
                <h3 className="text-md font-semibold text-gray-900 mb-3">
                  Select Delivery Address
                </h3>
                {userAddresses.length > 0 ? (
                  <div className="space-y-3 mb-4">
                    <div>
                      <label
                        htmlFor="deliveryAddress"
                        className="block text-sm font-medium text-gray-700 mb-1"
                      >
                        Choose an address *
                      </label>
                      <select
                        id="deliveryAddress"
                        required
                        className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-orange focus:border-primary-orange"
                        value={selectedAddressId || ""}
                        onChange={(e) => setSelectedAddressId(e.target.value)}
                      >
                        <option value="" disabled>
                          Select an address
                        </option>
                        {userAddresses.map((address) => (
                          <option key={address.id} value={address.id}>
                            {address.street_address}, {address.city},{" "}
                            {address.state_province} ({address.full_name},{" "}
                            {address.phone_number})
                          </option>
                        ))}
                      </select>
                    </div>
                    {selectedAddressId && (
                      <div className="p-3 border border-gray-200 rounded-md bg-gray-50 text-sm text-gray-700">
                        <p>
                          <strong>Name:</strong> {deliveryDetails.name}
                        </p>
                        <p>
                          <strong>Phone:</strong> {deliveryDetails.phone}
                        </p>
                        <p>
                          <strong>Address:</strong> {deliveryDetails.address},{" "}
                          {deliveryDetails.state}
                        </p>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg text-sm text-blue-800 flex items-start">
                    <Info className="w-5 h-5 text-blue-600 mr-2 mt-0.5" />
                    <div>
                      <p className="font-medium mb-1">No addresses found.</p>
                      <p>
                        Please add a delivery address in your{" "}
                        <button
                          onClick={() => navigate("/settings")}
                          className="text-blue-700 underline hover:no-underline"
                        >
                          profile settings
                        </button>{" "}
                        to proceed with checkout.
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex flex-col space-y-4">
                  <FlutterwavePayment
                    amount={paymentAmount}
                    onSuccess={handleFlutterwaveSuccess}
                    onClose={handleFlutterwaveClose}
                    customerInfo={{
                      name: deliveryDetails.name,
                      email: user?.email || "",
                      phone: deliveryDetails.phone,
                    }}
                    disabled={isCheckoutDisabled}
                    orderId={orderId ?? undefined}
                    onInit={handleFlutterwaveInit}
                    className="w-full bg-primary-orange text-white py-3 rounded-lg hover:bg-primary-orange/90 transition-colors flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <CreditCard className="w-5 h-5" />
                    <span>
                      {checkoutLoading
                        ? "Processing..."
                        : `Pay ${formatPrice(paymentAmount)} with Flutterwave`}
                    </span>
                  </FlutterwavePayment>
                  <button
                    onClick={() => {
                      // Only use allowed types for showNotification
                      showNotification(
                        "Mixpay integration is coming soon!",
                        "success"
                      );
                      // In a real app, you might trigger a different flow or show a modal
                      window.location.href =
                        "https://mixpay.me/ulishastore/checkout";
                    }}
                    disabled={isCheckoutDisabled} // Use the same disabled logic
                    className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <svg
                      className="w-5 h-5"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2z"></path>
                      <path d="M12 16v-4"></path>
                      <path d="M12 8h.01"></path>
                    </svg>
                    <span>Pay with Mixpay </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      {/* Show receipt modal if needed */}
      {showReceipt && currentOrder && <OrderReceipt order={currentOrder} />}
    </div>
  );
}
