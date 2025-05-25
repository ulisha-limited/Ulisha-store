import React from 'react'
import { RefreshCw } from 'lucide-react'

export function Returns() {
  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-md p-8">
          <div className="flex items-center justify-center mb-8">
            <RefreshCw className="h-12 w-12 text-primary-orange" />
          </div>

          <h1 className="text-3xl font-bold text-gray-900 text-center mb-8">Return Policy</h1>

          <div className="prose max-w-none">
            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">1. Return Period</h2>
              <p className="text-gray-600 mb-4">
                We accept returns within 7 days of delivery for most items. To be eligible for a
                return, your item must be unused and in the same condition that you received it.
              </p>
              <p className="text-gray-600">
                The item must be in its original packaging with all tags and labels attached.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">2. Non-Returnable Items</h2>
              <p className="text-gray-600 mb-4">The following items cannot be returned:</p>
              <ul className="list-disc list-inside text-gray-600 mb-4">
                <li>Personal care items</li>
                <li>Intimate apparel</li>
                <li>Customized or personalized products</li>
                <li>Downloadable software products</li>
                <li>Gift cards</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">3. Return Process</h2>
              <p className="text-gray-600 mb-4">To initiate a return, please follow these steps:</p>
              <ol className="list-decimal list-inside text-gray-600 mb-4">
                <li className="mb-2">
                  Contact our customer service team within 7 days of receiving your order
                </li>
                <li className="mb-2">Obtain a Return Merchandise Authorization (RMA) number</li>
                <li className="mb-2">Pack the item securely in its original packaging</li>
                <li className="mb-2">Include the RMA number on the outside of the package</li>
                <li>Ship the item to the address provided by our customer service team</li>
              </ol>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">4. Refunds</h2>
              <p className="text-gray-600 mb-4">
                Once we receive and inspect your return, we will notify you of the approval or
                rejection of your refund.
              </p>
              <p className="text-gray-600 mb-4">
                If approved, your refund will be processed, and a credit will automatically be
                applied to your original method of payment within 7-14 business days.
              </p>
              <p className="text-gray-600">
                Please note that shipping costs are non-refundable, and you will be responsible for
                the cost of returning the item.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">
                5. Damaged or Defective Items
              </h2>
              <p className="text-gray-600 mb-4">
                If you receive a damaged or defective item, please contact us immediately with
                photos of the damage. We will provide a prepaid shipping label for return and send a
                replacement item.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">
                6. Late or Missing Refunds
              </h2>
              <p className="text-gray-600 mb-4">
                If you haven't received a refund yet, first check your bank account again. Then
                contact your credit card company, it may take some time before your refund is
                officially posted.
              </p>
              <p className="text-gray-600">
                If you've done all of this and you still have not received your refund yet, please
                contact us at support@ulishastore.com.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">7. Exchanges</h2>
              <p className="text-gray-600 mb-4">
                We only replace items if they are defective or damaged. If you need to exchange it
                for the same item in a different size or color, send us an email at
                support@ulishastore.com.
              </p>
            </section>

            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">8. Contact Us</h2>
              <p className="text-gray-600 mb-4">
                If you have any questions about our Return Policy, please contact us:
              </p>
              <ul className="list-disc list-inside text-gray-600">
                <li>Email: support@ulishastore.com</li>
                <li>Phone: +234 (0) 706 043 8205</li>
                <li>WhatsApp: +234 (0) 706 043 8205</li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  )
}
