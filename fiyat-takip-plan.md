# Mağaza Fiyat Takip Uygulaması — Antigravity Uygulama Planı

> Bu doküman bir tasarım/planlama çıktısıdır. Kod içermez. Antigravity bu planı adım adım, sırayla uygulamalıdır. Her adım tamamlandığında sonuç (log, ekran görüntüsü, hata çıktısı) geliştiriciye raporlanmalıdır.

---

## 1. Proje Özeti

Küçük bir elektrik malzemeleri / nalbur tarzı mağaza için, ürün fotoğrafı çekip alış-satış fiyatlarını kaydeden, 2-3 çalışanın eş zamanlı ve **offline** olarak kullanabileceği bir fiyat takip uygulaması.

**Ana özellikler:**
- 📸 Kamera ile ürün fotoğrafı çekme
- 💲 Alış fiyatı / satış fiyatı ayrı girişi
- 🕒 Fiyat geçmişi (bir ürünün geçmiş fiyat değişimleri görüntülenebilir)
- 🗂️ Sabit (geliştirici tanımlı) kategori listesi
- 👥 Her çalışan için ayrı hesap (Firebase Auth), herkes aynı yetkiye sahip
- 🔌 **Offline-first**: internet olmadan da ürün eklenip görüntülenebilir, bağlantı gelince otomatik senkronize olur
- 🖥️ Hedef platformlar: Android, iOS, Windows masaüstü

---

## 2. Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Framework | Flutter (Android, iOS, Windows) |
| State Management | Riverpod |
| Yerel Veritabanı (offline) | Isar |
| Bulut / Senkron | Firebase (Firestore + Storage + Auth) |
| Navigasyon | GoRouter |
| Kamera | `image_picker` veya `camera` paketi |

**Not:** SDK yolu `A:\flutter` (Windows) — mevcut kurulum kullanılacak.

---

## 3. Firebase Kurulumu (Antigravity için görev)

1. Yeni bir Firebase projesi oluştur: `stok-takip-app` (isim onay için sorulacak)
2. Firestore, Storage ve Authentication (Email/Password) servislerini etkinleştir
3. Android, iOS ve Windows için Firebase config dosyalarını projeye ekle
4. Placeholder credential alanları:
   - `FIREBASE_API_KEY: <BURAYA_GİRİLECEK>`
   - `FIREBASE_PROJECT_ID: <BURAYA_GİRİLECEK>`
   - `FIREBASE_APP_ID (android/ios/windows): <BURAYA_GİRİLECEK>`

---

## 4. Veri Modeli

### Isar (yerel) + Firestore (bulut) — aynı şema, iki katmanda

**Ürün (`Product`)**
```
id: String (uuid)
ad: String
kategori: String (sabit listeden)
alisFiyati: double
satisFiyati: double
resimYolu: String (yerel dosya yolu)
resimUrl: String? (Firebase Storage, sync sonrası dolar)
olusturmaTarihi: DateTime
guncellemeTarihi: DateTime
guncelleyenKullanici: String (uid)
senkronDurumu: enum (bekliyor / senkronize)
```

**Fiyat Geçmişi (`PriceHistory`)**
```
id: String (uuid)
urunId: String
eskiAlisFiyati: double
eskiSatisFiyati: double
degisimTarihi: DateTime
degistirenKullanici: String (uid)
```

### Sabit Kategori Listesi
```
- Televizyon & Uydu
- Elektrik Tesisatı
- Kablo & Şarj Aksesuarları
- Küçük Ev Aletleri
- Boya & Kimyasal
- Diğer
```
> Not: Bu liste ileride genişletilecek. Kategoriler kod içinde tek bir `enum` veya `const list` dosyasında (`lib/core/constants/categories.dart`) tutulmalı — böylece yeni kategori eklemek tek dosyada tek satırlık değişiklik olur, uygulama içinden kullanıcı ekleyemez.

---

## 5. Offline-First Senkronizasyon Stratejisi

1. Tüm yazma işlemleri **önce Isar'a** yazılır (anında, internet gerektirmez)
2. Her kayda `senkronDurumu: bekliyor` etiketi konur
3. Arka planda bir `SyncService`:
   - Bağlantı algıladığında (`connectivity_plus` paketi) bekleyen kayıtları Firestore'a gönderir
   - Firestore `onSnapshot` ile diğer cihazlardaki güncellemeleri dinler, Isar'ı günceller
   - Çakışma durumunda: **son yazma kazanır** (timestamp bazlı), ileride manuel çakışma çözümü eklenebilir
4. Fotoğraflar önce yerel dosya sisteminde tutulur, senkron sırasında Firebase Storage'a yüklenir ve `resimUrl` doldurulur

---

## 6. Ekran Akışı

1. **Giriş Ekranı** — Firebase Auth (email/şifre)
2. **Ana Sayfa** — Kategoriye göre filtrelenebilir ürün listesi (grid, fotoğraflı)
3. **Ürün Ekle** — Kamera aç → fotoğraf çek → ad, kategori (dropdown, sabit liste), alış/satış fiyatı gir → kaydet
4. **Ürün Detay** — Fotoğraf, tüm bilgiler, "Fiyat Geçmişi" sekmesi, düzenle butonu
5. **Fiyat Geçmişi** — Zaman sıralı liste (tarih, eski/yeni fiyat, kim değiştirdi)
6. **Düzenleme** — Fiyat değiştirildiğinde otomatik olarak `PriceHistory` kaydı oluşturulur

---

## 7. Masaüstü (Windows) Notları

- Kamera yerine dosya seçici (galeri/dosya sistemi) fallback olarak eklenmeli
- Grid/list layout'lar geniş ekrana göre responsive olmalı (Riverpod ile aynı state, farklı layout)

---

## 8. Antigravity için Sıralı Görev Listesi

1. Flutter projesini oluştur, Riverpod + GoRouter + Isar bağımlılıklarını ekle
2. Firebase projesini bağla (bkz. Bölüm 3), Auth ekranını kur
3. Isar şemasını oluştur (Bölüm 4), temel CRUD servislerini yaz
4. Ana Sayfa + Ürün Ekle ekranlarını kur (kamera entegrasyonu dahil)
5. `SyncService`'i kur (Bölüm 5), bağlantı durumu göstergesi ekle (UI'da küçük bir "senkronize/bekliyor" ikonu)
6. Ürün Detay + Fiyat Geçmişi ekranlarını kur
7. Windows platformu için build ayarlarını yap, dosya seçici fallback'i ekle
8. Uçtan uca test: 2 cihazda offline ekleme → bağlantı → senkron kontrolü

Her adımdan sonra sonucu (build çıktısı, hata varsa tam log) bir sonraki adıma geçmeden raporla.

---

## 9. Sonraki Aşamada Değerlendirilebilecekler

- Barkod/QR okuma (şu an istenmiyor, ama kategori listesi genişledikçe faydalı olabilir)
- Kategori listesinin genişletilmesi (mağazada elektrik tesisatı ürünleri çok çeşitli — TV/uydu, kablo, aksesuar, boya/kimyasal, küçük ev aletleri dışında alt kategoriler gerekebilir)
- Kâr marjı otomatik hesaplama
- Basit raporlama (en çok satılan / en çok güncellenen ürünler)
