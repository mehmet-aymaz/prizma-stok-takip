# Prizma — Fiyat ve Ürün Takip Uygulaması / Price & Product Tracking App

[README in English](#english)

Prizma, küçük işletmeler ve mağazalar için tasarlanmış, modern ve gelişmiş bir **çevrimdışı öncelikli (offline-first)** fiyat ve ürün takip uygulamasıdır.

Bu uygulama sayesinde internet bağlantınız olmasa dahi ürünlerinizi kaydedebilir, fotoğraflarını çekebilir, alış/satış fiyatlarını güncelleyebilirsiniz. İnternet bağlantısı sağlandığında tüm veriler otomatik olarak Firebase ile senkronize edilir.

---

## 🚀 Özellikler

- **📸 Ürün Fotoğraflama:** Cihaz kamerası ile hızlıca ürün fotoğrafları çekme ve yerel/bulut depolamaya kaydetme.
- **💲 Ayrı Alış ve Satış Fiyatları:** Alış ve satış fiyatlarını ayrı ayrı girip takip edebilme.
- **🕒 Fiyat Geçmişi:** Ürünlerin fiyat değişim geçmişlerini tarih ve değiştiren kullanıcı bilgisiyle izleme.
- **🗂️ Kategori Yönetimi:** Ürünleri belirli ve düzenli kategorilere ayırarak listeleme.
- **👥 Çoklu Kullanıcı & Eş Zamanlılık:** Firebase Auth ile çalışan her personel için ayrı hesap açma ve aynı veriler üzerinde eş zamanlı çalışabilme.
- **🔌 Çevrimdışı Öncelikli (Offline-first) Mimari:** İnternet yokken yerel veritabanına (Isar DB) yazma; bağlantı kurulduğunda arka planda otomatik bulut senkronizasyonu (Firestore & Storage).
- **🖥️ Çoklu Platform Desteği:** Android, iOS ve Windows Masaüstü desteği.

---

## 🛠️ Teknoloji Yığını

- **Framework:** Flutter (Dart)
- **Durum Yönetimi (State Management):** Riverpod (flutter_riverpod)
- **Yerel Veritabanı:** Isar Database
- **Bulut Altyapısı & Senkronizasyon:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
- **Navigasyon:** GoRouter

---

## 📋 Gereksinimler ve Kurulum

Projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyebilirsiniz:

1. **Flutter SDK:** Bilgisayarınızda Flutter SDK'nın kurulu olduğundan emin olun (SDK sürümü `>=3.12.2`).
2. **Depoları Çekme:**
   ```bash
   git clone https://github.com/mehmet-aymaz/prizma-stok-takip.git
   cd prizma-stok-takip
   ```
3. **Bağımlılıkları Yükleme:**
   ```bash
   A:\flutter\bin\flutter.bat pub get
   ```
4. **Firebase Yapılandırması:**
   Uygulamanın çalışabilmesi için kendi Firebase projenizi oluşturmalı ve aşağıdaki dosyaları ilgili dizinlere yerleştirmelisiniz:
   - **Android:** `android/app/google-services.json`
   - **iOS:** `ios/Runner/GoogleService-Info.plist`
   - Firebase projenizde **Email/Password Authentication**, **Cloud Firestore** ve **Firebase Storage** servislerinin aktif olduğundan emin olun.
5. **Uygulamayı Çalıştırma:**
   ```bash
   A:\flutter\bin\flutter.bat run
   ```

---

<a id="english"></a>
# Prizma — Price & Product Tracking App

Prizma is a modern, advanced **offline-first** price and product tracking application designed for small businesses and retail shops.

With this app, you can save products, capture product photos, and update cost/selling prices even without an internet connection. Once internet connection is established, all data automatically syncs with Firebase.

---

## 🚀 Features

- **📸 Product Photo Capture:** Quickly take product photos using the device camera and save them locally and to the cloud.
- **💲 Separate Cost & Selling Prices:** Enter and track purchasing (cost) and sales prices independently.
- **🕒 Price History:** Track price change history over time with date and the modifying user details.
- **🗂️ Category Management:** Organize and list products under specific categories.
- **👥 Multi-User & Synchronization:** Firebase Auth support allowing each staff member to sign in separately and work on the same data concurrently.
- **🔌 Offline-first Architecture:** Writes to local Isar DB when offline; automatically syncs to Firestore & Firebase Storage in the background when connected.
- **🖥️ Multi-Platform Support:** Ready for Android, iOS, and Windows Desktop.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (flutter_riverpod)
- **Local Database:** Isar Database
- **Cloud Infrastructure & Sync:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
- **Navigation:** GoRouter

---

## 📋 Requirements and Setup

To run the project locally, follow these steps:

1. **Flutter SDK:** Ensure you have Flutter SDK installed (SDK version `>=3.12.2`).
2. **Clone the Repository:**
   ```bash
   git clone https://github.com/mehmet-aymaz/prizma-stok-takip.git
   cd prizma-stok-takip
   ```
3. **Install Dependencies:**
   ```bash
   A:\flutter\bin\flutter.bat pub get
   ```
4. **Firebase Setup:**
   Create a Firebase project and place the configuration files in the appropriate directories:
   - **Android:** `android/app/google-services.json`
   - **iOS:** `ios/Runner/GoogleService-Info.plist`
   Ensure Email/Password Authentication, Cloud Firestore, and Firebase Storage are enabled.
5. **Run the App:**
   ```bash
   A:\flutter\bin\flutter.bat run
   ```

---
*Geliştirme / Developed by: Antigravity AI Code Assistant | Temmuz 2026*
