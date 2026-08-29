# 🍏 CalTrack - Smart Calorie Tracker

CalTrack adalah aplikasi pelacak nutrisi, hidrasi, dan kebugaran cerdas berbasis mobile (*cross-platform*). Dibangun menggunakan **Flutter** dan **Supabase**, aplikasi ini mengintegrasikan **Artificial Intelligence (Google Gemini)** untuk memberikan pengalaman pencatatan makanan (*food logging*) yang otomatis, intuitif, dan mutakhir.

## ✨ Fitur Unggulan

- 🤖 **AI-Powered Food Logging:** Catat makanan hanya dengan mengetik bahasa sehari-hari (contoh: *"Makan 2 mangkok mie ayam dan 1 telur rebus"*). AI akan otomatis mengekstrak nama makanan, menghitung porsi, dan mencari kecocokan nutrisi (Kalori, Protein, Karbo, Lemak) dari *database*.
- 📊 **Smart Dashboard:** Pantau kalori bersih (*net calories*), metrik makro (Protein, Karbo, Lemak), dan progres hidrasi secara *real-time* dengan animasi antarmuka yang sangat mulus (*Glassmorphism UI*).
- 💧 **Water Tracker:** Lacak asupan air harian dengan target khusus yang dihitung secara otomatis berdasarkan berat badan.
- 🏋️ **Workout Tracker:** Catat aktivitas olahraga dengan lebih dari puluhan kategori latihan. Estimasi kalori yang terbakar dihitung secara dinamis berdasarkan durasi dan rasio berat badan pengguna.
- 📈 **Progress Analytics:** Visualisasi data historis (mingguan, bulanan, tahunan) untuk memantau tren penurunan/kenaikan berat badan, konsumsi kalori, dan durasi latihan.
- 🌗 **Adaptive Theme:** Dukungan penuh untuk *Light Mode* dan *Dark Mode* yang responsif terhadap pengaturan sistem perangkat.
- 🌍 **Bilingual Support:** Tersedia dalam Bahasa Indonesia dan Bahasa Inggris.
- 🔐 **Secure Authentication:** Sistem login/register yang aman melalui Email/Password dan Google Sign-In, lengkap dengan fitur *reset password* (Deep Linking).

## 🛠️ Teknologi & Arsitektur (Tech Stack)

Aplikasi ini mengadopsi **Feature-First Architecture** dan memisahkan *Presentation Layer* (UI) dengan *Service Layer* (Logika Bisnis & Database) untuk memastikan kode yang *scalable* dan bersih (*Clean Code*).

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend (BaaS):** [Supabase](https://supabase.com/) (PostgreSQL, Authentication)
- **Artificial Intelligence:** Google Generative AI (Gemini 3.5 Flash-lite)
- **State Management:** Provider
- **Local Storage:** Shared Preferences

## 📁 Struktur Direktori

```text
lib/
├── core/
│   ├── providers/     # State management (contoh: ThemeProvider)
│   ├── services/      # Pusat logika backend (Auth, AI, Database Fetching)
│   ├── theme/         # Konfigurasi warna, tipografi, dan mode gelap/terang
│   └── utils/         # Utilitas aplikasi (contoh: AppLocalization)
├── features/
│   ├── auth/          # Modul Autentikasi (Login, Register)
│   ├── dashboard/     # Tampilan Utama & Navigasi
│   ├── onboarding/    # Flow registrasi data fisik (BMI & TDEE Calculator)
│   ├── profile/       # Pengaturan profil dan preferensi bahasa/tema
│   ├── progress/      # Modul analitik dan grafik riwayat pengguna
│   ├── splash/        # Splash screen & logika routing awal
│   └── tracker/       # Layar pelacakan utama (Makanan, Air, Olahraga)
└── main.dart          # Entry point aplikasi
