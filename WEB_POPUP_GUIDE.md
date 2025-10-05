# Web Popup Checkout Guide

## 🚀 How It Works

### For Sellers:
1. **Create a Product** in the app
2. **Generate a Link** for the product
3. **Share the link** on Instagram, Facebook, WhatsApp, or anywhere
4. **Receive orders** when buyers click and checkout

### For Buyers:
1. **Click the product link** (e.g., `https://checkout-e765c.web.app/checkout?product=ABC123`)
2. **View product details** - Image, price, description, variants
3. **Select quantity** and any product variants (size, color, etc.)
4. **Click "Proceed to Checkout"**
5. **Fill in delivery details** - Name, phone, email, address
6. **Confirm order** - Currently uses Cash on Delivery (COD)
7. **Get confirmation** - Order code and tracking info

## 🔗 Link Format

### Product Checkout Link:
```
https://checkout-e765c.web.app/checkout?product={PRODUCT_ID}
```

### With Variants (Optional):
```
https://checkout-e765c.web.app/checkout?product={PRODUCT_ID}&size=Large&color=Blue
```

### Order Tracking Link:
```
https://checkout-e765c.web.app/track?order={ORDER_CODE}
```

## 📱 Testing the Web Popup

### Method 1: Use Firebase Hosting
1. Deploy to Firebase: `firebase deploy --only hosting`
2. Open: `https://checkout-e765c.web.app/checkout?product=YOUR_PRODUCT_ID`

### Method 2: Local Testing
1. Run: `flutter run -d chrome --web-port=8080`
2. Open: `http://localhost:8080/checkout?product=YOUR_PRODUCT_ID`

## 🛠️ Current Implementation Status

### ✅ Working Features:
- URL parsing to extract product ID
- Loading product from Firebase
- Product display with images, variants, quantity
- Checkout form with validation
- Order creation in Firebase
- Confirmation page with order details
- Cash on Delivery (COD) payment

### ⏳ Coming Soon:
- Card payment integration (D17, Flouci, Stripe)
- Order tracking page
- QR code generation
- SMS notifications
- Email confirmations

## 💡 Payment Methods

### Current: Cash on Delivery (COD)
- Buyer pays when receiving the order
- Seller confirms order manually
- No upfront payment required

### Future: Online Payment
- Integrate payment gateways:
  - **D17** - Tunisian payment gateway
  - **Flouci** - Mobile payment
  - **Stripe** - International cards

## 🔐 Security Notes

### Files to NEVER commit to GitHub:
- ✅ Already protected:
  - `android/app/google-services.json` - Contains Firebase API key
  - `.firebaserc` - Contains project ID

### Safe to commit:
- `firebase.json` - Configuration only, no secrets
- All Dart source code
- Web popup implementation

## 📊 Flow Diagram

```
Seller Creates Product
        ↓
Generate Shareable Link
        ↓
Post on Social Media
        ↓
Buyer Clicks Link
        ↓
Web Popup Opens → Product Details
        ↓
Buyer Selects Options
        ↓
Checkout Form → Fill Details
        ↓
Confirm Order
        ↓
Order Saved to Firebase
        ↓
Seller Notified
        ↓
Confirmation Page → Order Code
        ↓
Seller Contacts Buyer
        ↓
Delivery Arranged
```

## 🐛 Troubleshooting

### Issue: "Product not found"
**Solution:** Check that:
- Product ID in URL is correct
- Product exists in Firebase `products` collection
- Product `isActive` field is `true`

### Issue: "Invalid product link"
**Solution:** Ensure URL format is correct:
- Must have `?product=` parameter
- Product ID must not be empty

### Issue: Order not appearing for seller
**Solution:**
- Check Firebase Console → `orders` collection
- Verify `sellerId` matches the seller's user ID
- Check order status is `pending` or `confirmed`

## 🎨 Customization

### Change Payment Method:
Edit `lib/presentation/buyer/web_popup/checkout_popup_form.dart`:
```dart
paymentMethod: FirebaseConstants.paymentCOD, // or paymentD17, paymentFlouci
```

### Change Order Status:
```dart
status: FirebaseConstants.orderStatusPending, // or orderStatusConfirmed
```

### Change Delivery Fee:
```dart
final double _deliveryFee = 7.000; // Change this value
```

## 📞 Support

For issues or questions:
1. Check Firebase Console for errors
2. Check browser console for JavaScript errors
3. Verify Firebase rules allow read/write access
4. Test with a real product ID from your database
