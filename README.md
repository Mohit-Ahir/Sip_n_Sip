# ☕ Sip & Sip - Premium Coffee E-Commerce App

Sip & Sip is a high-performance, full-stack mobile application built using Flutter and Firebase. It offers a premium experience for coffee lovers and a powerful management dashboard for café owners.

---

## ⚠️ Security Notice

For security reasons, all Private API Keys and Firebase Configuration files have been removed from this public repository.

To run this project on your local machine, you must follow the setup instructions below to add your own keys.

---

# 🚀 Key Features

## 👤 Customer Features

- Personalized UI: Dynamic time-based greetings and premium coffee-themed design.
- Customization: Select Size and Sugar levels with real-time price updates.
- Smart Checkout: Free map integration for precise delivery address selection.
- Secure Payments: Integrated with Razorpay (Test Mode) and Cash on Delivery.
- Profile: Manage your account and upload profile photos via ImgBB.

---

## 🛡️ Admin Features

- Live Analytics: Real-time tracking of Revenue, Orders, and Customers.
- Inventory CRUD: Add, Edit, and Delete coffee products with image cropping.
- Low Stock Alerts: Automatic notifications when product quantity falls below 5.
- Order Management: Change order status (Preparing/Delivered) in real-time.

---

# 🛠️ Setup Instructions

## 1. Firebase Configuration

You need to connect your own Firebase project.

### Step 1

Create a project at Firebase Console.

### Step 2

Add an Android app with your package name.

Example:

```
com.example.sip_and_sip
```

### Step 3

Download the `google-services.json` file and place it in:

```
android/app/google-services.json
```

### Step 4

Generate your `lib/firebase_options.dart` using the FlutterFire CLI or manually fill in your project IDs.

---

## 2. External API Keys

You must provide your own keys in the following files.

### A. ImgBB (Image Hosting)

Get a free key at:

```
api.imgbb.com
```

Paste it in:

```
lib/Admin/AddProductPage.dart
lib/Admin/EditProductPage.dart
lib/User/EditProfile.dart
lib/Admin/EditAdminProfilePage.dart
```

---

### B. Razorpay (Payments)

Get a test key at:

```
dashboard.razorpay.com
```

Paste it in:

```
lib/User/CheckoutPage.dart
```

---

# 📦 Required Packages

Run the following command to install all dependencies.

```bash
flutter pub get
```

### Key Dependencies

- firebase_auth
- cloud_firestore
- google_sign_in
- razorpay_flutter
- flutter_map
- geolocator
- image_picker
- image_cropper
- cached_network_image
- http

---

# 📱 Android Setup (Important)

For the Image Cropper to work, ensure you have added this to your

```
android/app/src/main/AndroidManifest.xml
```

inside the `<application>` tag.

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

---

# 📝 License

This project was developed for educational purposes at RK University.

Feel free to explore and improve the code!

---

# 📤 How to Add This README to GitHub

1. Open VS Code.
2. Create/Open `README.md`.
3. Paste the content above.
4. Run these commands:

```bash
git add README.md
git commit -m "Added comprehensive README for project setup"
git push origin main
```
