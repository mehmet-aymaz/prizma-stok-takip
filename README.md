# Prizma Fiyat Takip Uygulaması

Prizma, küçük işletmeler ve mağazalar için tasarlanmış, modern ve gelişmiş bir **çevrimdışı öncelikli (offline-first)** fiyat ve ürün takip uygulamasıdır.

Bu uygulama sayesinde internet bağlantınız olmasa dahi ürünlerinizi kaydedebilir, fotoğraflarını çekebilir, alış/satış fiyatlarını güncelleyebilirsiniz. İnternet bağlantısı sağlandığında tüm veriler otomatik olarak Firebase ile senkronize edilir.

## 🚀 Özellikler

* **📸 Ürün Fotoğraflama:** Cihaz kamerası ile hızlıca ürün fotoğrafları çekme ve kaydetme.
* **💲 Ayrı Alış ve Satış Fiyatları:** Alış ve satış fiyatlarını ayrı ayrı girip takip edebilme.
* **🕒 Fiyat Geçmişi:** Ürünlerin fiyat değişim geçmişlerini tarih ve değiştiren kullanıcı bilgisiyle izleme.
* **🗂️ Kategori Yönetimi:** Ürünleri belirli ve düzenli kategorilere ayırarak listeleme.
* **👥 Çoklu Kullanıcı & Eş Zamanlılık:** Firebase Auth ile çalışan her personel için ayrı hesap açma ve aynı veriler üzerinde eş zamanlı çalışabilme.
* **🔌 Offline-first Mimari:** İnternet yokken yerel veritabanına (Isar DB) yazma; bağlantı kurulduğunda arka planda otomatik bulut senkronizasyonu (Firestore & Storage).
* **🖥️ Çoklu Platform Desteği:** Android, iOS ve Windows Masaüstü desteği.

## 🛠️ Teknoloji Yığını

* **Framework:** Flutter (Dart)
* **Durum Yönetimi (State Management):** Riverpod (flutter_riverpod)
* **Yerel Veritabanı:** Isar Database
* **Bulut Altyapısı & Senkronizasyon:** Firebase (Authentication, Cloud Firestore, Firebase Storage)
* **Navigasyon:** GoRouter

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
   flutter pub get
   ```
4. **Firebase Yapılandırması:**
   Uygulamanın çalışabilmesi için kendi Firebase projenizi oluşturmalı ve aşağıdaki dosyaları ilgili dizinlere yerleştirmelisiniz:
   * **Android:** `android/app/google-services.json`
   * **iOS:** `ios/Runner/GoogleService-Info.plist`
   * Firebase projenizde **Email/Password Authentication**, **Cloud Firestore** ve **Firebase Storage** servislerinin aktif olduğundan emin olun.

5. **Uygulamayı Çalıştırma:**
   ```bash
   flutter run
   ```

## 📄 Lisans

Bu proje kişisel/mağaza kullanımına özel olarak geliştirilmiştir.
