# 💰 Gold Digger :D
### "Because your money shouldn't just fly away." 🇨🇦 🇮🇳

**Gold Digger** is a lightweight, privacy-focused expense tracker built with Flutter. It’s designed for those who want to keep an eye on their "Loonies" (and Rupees) without a bank or a cloud provider watching over their shoulder.

---

## 🛡️ Privacy First (Your Data, Your Device)
In an age where every app wants your email and a cloud subscription, **Gold Digger** takes a different route:
* **Local Storage:** All your transactions are stored in a local SQLite database on your phone.
* **No Cloud Sync:** Your data never leaves your device unless you choose to export it.
* **No Account Required:** Just install and start tracking.

---

## ✨ Features
* **Auto-Magic Caps:** Every entry starts with a capital letter automatically. Stay professional.
* **Visual Reports:** Simple Bar Charts to see your Inflow vs. Outflow at a glance.
* **Multi-Currency:** Support for **$ (CAD/USD)**, **₹ (INR)**, **£ (GBP)**, and **€ (EUR)**.
* **Historical Tracking:** Add expenses from yesterday or plan for tomorrow with the built-in Date Picker.
* **Profile Setup:** Personalized with your name and photo (saved locally).
* **Export to CSV:** Need to do taxes or deep-dive in Excel? Export your data anytime.

---

## 🚀 How to Use
1. **The Drawer:** Tap the menu icon to set your name and profile picture.
2. **Add Entry:** Hit the `+` button. Type the amount, pick a category (Mortgage, Groceries, etc.), and save.
3. **Monthly View:** Use the dropdown in the header to jump between months.
4. **Edit/Delete:** Long-press any item to fix a mistake, or swipe left to delete it.
5. **Report:** Tap the download icon to generate a CSV spreadsheet of your month.

---

## 🛠️ Build & Run
If you're building this from source:
1. Ensure Flutter is installed.
2. Run `flutter pub get`.
3. Build the APK: `flutter build apk --split-per-abi`.
4. Install `app-arm64-v8a-release.apk` on your Android device.
