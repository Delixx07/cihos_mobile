# Cihos Mobile

Aplikasi mobile pasien untuk **Ciputra Hospital Surabaya**, dibangun dengan
Flutter. Pasien dapat membuat janji temu dengan dokter, melakukan konsultasi
video, memantau antrean, melihat hasil pemeriksaan, dan membaca informasi
kesehatan — semuanya dari satu aplikasi.

Dikerjakan sebagai proyek magang di Ciputra Hospital Surabaya.

---

## Daftar Isi

- [Fitur](#fitur)
- [Tangkapan Layar](#tangkapan-layar)
- [Teknologi](#teknologi)
- [Memulai](#memulai)
- [Konfigurasi](#konfigurasi)
- [Struktur Proyek](#struktur-proyek)
- [Sistem Desain](#sistem-desain)
- [Integrasi Backend](#integrasi-backend)
- [Pengujian](#pengujian)
- [Status Pengembangan](#status-pengembangan)

---

## Fitur

### Autentikasi
- **Login** dengan email dan password
- **Registrasi pasien baru** dengan NIK, data diri, dan kontak
- Sesi tersimpan aman — pasien tidak perlu login ulang setiap membuka aplikasi
- Onboarding untuk pengguna pertama kali

### Janji Temu & Konsultasi
- **Janji Temu Dokter** — pilih spesialisasi, dokter, tanggal, dan jam praktik
- **Video Call Dokter** — telekonsultasi dengan alur yang sama
- Kalender praktik yang menandai hari praktik dan libur
- Pilih pasien (diri sendiri atau anggota keluarga)
- Pilih jenis jaminan: pribadi atau asuransi/perusahaan
- Ringkasan sebelum konfirmasi, dengan opsi mengubah dokter, jadwal, atau pasien
- Booking ID & QR code untuk check-in di rumah sakit

### Pengelolaan Jadwal
- Daftar janji temu yang akan datang
- Detail janji temu lengkap dengan perkiraan biaya terperinci
- Pembatalan jadwal dengan pilihan alasan
- **Riwayat** kunjungan yang sudah selesai, dengan tombol "Buat Janji Ulang"

### Layanan Rumah Sakit
- **Cari Dokter** — pencarian dan filter berdasarkan spesialisasi
- **Monitor Antrean** — pantau nomor antrean secara langsung
- **Cek Antrian** — status antrean hari ini
- **Hasil Pemeriksaan** — laboratorium dan radiologi
- **Paket MCU** — daftar paket medical check-up
- **Gawat Darurat** — akses cepat ke informasi IGD
- **Promo** — penawaran layanan rumah sakit

### Informasi & Profil
- **Info Kesehatan** — artikel kesehatan dalam beberapa kategori
- **Sehat-mu** — ringkasan kondisi kesehatan pribadi
- **Notifikasi** — pemberitahuan janji temu dan informasi rumah sakit
- **Profil** — data diri pasien dan pengaturan akun

---

## Tangkapan Layar

Tangkapan layar acuan tersimpan sebagai *golden test* di
[`test/goldens/`](test/goldens/). Berkas-berkas ini bukan sekadar dokumentasi —
lihat [Pengujian](#pengujian).

---

## Teknologi

| Komponen | Pilihan | Alasan |
|---|---|---|
| Framework | Flutter 3.41 / Dart 3.11 | Satu basis kode untuk Android dan iOS |
| State management | [Riverpod](https://riverpod.dev) 2.6 | Aman terhadap tipe, mudah diuji, tanpa `BuildContext` |
| Navigasi | [go_router](https://pub.dev/packages/go_router) 17.5 | Rute deklaratif dengan penjaga autentikasi |
| HTTP | [Dio](https://pub.dev/packages/dio) 5.11 | Interceptor dan penanganan error terpusat |
| Penyimpanan token | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) 11 | Keystore terenkripsi, bukan berkas teks biasa |
| Tipografi | [google_fonts](https://pub.dev/packages/google_fonts) | Kumbh Sans + Inter |
| Lokalisasi | `flutter_localizations` + `intl` | Format tanggal dan angka Indonesia (`id_ID`) |

**Skala proyek:** 100 berkas Dart, ±17.000 baris, 30 rute, 19 modul fitur.

---

## Memulai

### Prasyarat

- Flutter SDK 3.41 atau lebih baru
- Android SDK 37 (dibutuhkan `flutter_secure_storage`)
- Perangkat Android atau emulator

### Instalasi

```bash
git clone https://github.com/Delixx07/cihos_mobile.git
cd cihos_mobile
flutter pub get
```

### Menjalankan

```bash
cp env.example.json env.json   # lalu isi MOBILE_API_KEY
flutter run --dart-define-from-file=env.json
```

> **Penting:** aplikasi ini **harus** dijalankan dengan
> `--dart-define-from-file=env.json`. Tanpa itu, `MOBILE_API_KEY` kosong dan
> semua permintaan ke server akan ditolak dengan 401.

### Membangun APK

```bash
flutter build apk --release --dart-define-from-file=env.json
```

---

## Konfigurasi

Konfigurasi dibaca saat *build*, bukan dari berkas yang ikut ter-*commit*.
Salin `env.example.json` menjadi `env.json` dan isi nilainya:

```json
{
  "API_BASE_URL": "http://172.20.0.39/appointment",
  "MOBILE_API_KEY": "<kunci dari .env backend>"
}
```

| Kunci | Keterangan |
|---|---|
| `API_BASE_URL` | Alamat dasar API Laravel, tanpa garis miring di akhir |
| `MOBILE_API_KEY` | Kunci bersama yang dikirim sebagai header `X-Api-Key` |

`env.json` sudah tercantum di `.gitignore` dan tidak akan ikut ter-*commit*.

### Catatan keamanan

Ada dua hal yang perlu disadari sebelum aplikasi ini dipakai di luar lingkungan
uji:

1. **Kunci API di dalam APK tidak benar-benar rahasia.** Siapa pun dapat
   membongkar berkas APK dan membacanya. Menjaganya di luar Git melindungi
   repositori, bukan berkas rilis. Pertahanan yang sesungguhnya adalah kunci ini
   hanya berlaku untuk `/api/app/*`, dan setiap data pasien tetap memerlukan
   *bearer token* milik pengguna itu sendiri.

2. **Server internal menggunakan HTTP, bukan HTTPS.** Selama pemakaian terbatas
   di jaringan rumah sakit, hal ini dapat diterima, dan
   [`network_security_config.xml`](android/app/src/main/res/xml/network_security_config.xml)
   mengizinkannya hanya untuk alamat tersebut. Jika aplikasi dipakai dari luar
   jaringan rumah sakit, **HTTPS menjadi wajib** — password yang melewati HTTP
   dapat disadap.

---

## Struktur Proyek

Struktur mengikuti pola *feature-first*: setiap fitur berdiri sendiri lengkap
dengan lapisan domain, data, dan presentasinya.

```
lib/
├── core/                    # Dipakai lintas fitur
│   ├── config/              # Konfigurasi build-time
│   ├── network/             # ApiClient, penanganan error, penyimpanan token
│   ├── router/              # Definisi rute dan penjaga autentikasi
│   ├── theme/               # Warna, tipografi, spasi, elevasi, motion
│   └── widgets/             # Komponen bersama
│
└── features/
    ├── auth/                # Login, registrasi, sesi
    ├── booking/             # Alur janji temu & video call (dipakai bersama)
    ├── doctors/             # Cari dokter, profil, jadwal praktik
    ├── schedule/            # Janji temu mendatang, detail, pembatalan
    ├── history/             # Kunjungan selesai, buat janji ulang
    ├── health_news/         # Artikel kesehatan
    ├── queue/               # Monitor & cek antrean
    ├── results/             # Hasil laboratorium dan radiologi
    └── ...                  # 19 modul fitur seluruhnya
```

Setiap fitur mengikuti pola yang sama:

```
features/<nama>/
├── domain/          # Model dan aturan bisnis
├── data/            # Repository (sumber data)
├── application/     # Controller Riverpod
└── presentation/    # Layar dan widget
```

**Catatan arsitektur:** alur Janji Temu dan Video Call memakai satu modul
`booking` yang sama, dibedakan oleh `BookingKind`. Keduanya hanya berbeda pada
teks, tenggat waktu pemesanan (30 hari vs 7 hari), dan daftar dokter — sehingga
menyalin seluruh alur akan menduplikasi ratusan baris tanpa manfaat.

---

## Sistem Desain

Token desain terkumpul di [`lib/core/theme/`](lib/core/theme/) sehingga tampilan
tetap konsisten di seluruh layar.

| Berkas | Isi |
|---|---|
| `app_colors.dart` | Palet warna dan aksen |
| `app_typography.dart` | Skala tipografi (Kumbh Sans, Inter) |
| `app_spacing.dart` | Spasi 4pt dan skala radius sudut |
| `app_elevation.dart` | Bayangan berlapis, 4 tingkat |
| `app_motion.dart` | Durasi dan kurva animasi |

Desain awal berasal dari Figma, namun sengaja dikembangkan lebih jauh agar
terasa lebih modern:

- **Bayangan berlapis** menggantikan bayangan tunggal yang keras dari ekspor
  Figma. Setiap tingkat menumpuk bayangan kontak yang rapat dengan bayangan
  ambien yang lebar — meniru cara cahaya jatuh sesungguhnya.
- **Skala radius yang konsisten** menggantikan 12 nilai acak hasil penyesuaian
  piksel di Figma. Radius 3–5px terbaca seperti sudut yang tidak disengaja.
- **Skala tipografi yang diperbaiki.** Ekspor Figma menempatkan sebagian besar
  teks pada ukuran 8–13px — rentang yang terlalu sempit sehingga tidak ada
  hierarki yang terbaca.
- **Ukuran proporsional.** Logo dan ilustrasi memakai persentase lebar layar,
  bukan piksel tetap dari kanvas 393px, agar tidak mengecil di perangkat nyata.
- **Umpan balik sentuhan.** `Pressable` membuat kartu sedikit mengecil saat
  ditekan; `StaggeredEntrance` memunculkan daftar secara berurutan.

Palet dan warna aksen dipertahankan sesuai desain asli.

---

## Integrasi Backend

Aplikasi terhubung ke API Laravel yang melayani sistem appointment rumah sakit.

### Endpoint autentikasi

| Endpoint | Kegunaan |
|---|---|
| `POST /api/app/register` | Membuat akun pasien baru |
| `POST /api/app/login` | Masuk dengan email dan password |
| `GET /api/app/me` | Memeriksa sesi yang tersimpan |
| `POST /api/app/logout` | Mencabut token |

Seluruh permintaan membawa header `X-Api-Key`. Permintaan yang membutuhkan
pasien yang sudah masuk juga membawa `Authorization: Bearer <token>`.

### Bentuk respons

```json
{ "ok": true, "token": "...", "patient": { "id": 1, "name": "...", "...": "..." } }
```

```json
{ "ok": false, "error": "invalid_credentials", "message": "Email atau password salah." }
```

Kegagalan diterjemahkan menjadi `ApiException` sehingga layar tidak perlu
memahami kode status HTTP maupun tipe milik Dio.

### Alur autentikasi

1. Pasien memasukkan email dan password
2. Server mengembalikan *bearer token*
3. Token disimpan di keystore terenkripsi perangkat
4. Saat aplikasi dibuka, splash screen memulihkan sesi sambil animasi berjalan
5. Token yang ditolak akan dihapus, dan pasien diminta masuk kembali

> **Catatan:** NIK hanya dikumpulkan saat registrasi pasien baru. Proses masuk
> menggunakan email dan password.

---

## Pengujian

```bash
flutter test                                        # seluruh pengujian
flutter test test/widget_test.dart                  # pengujian widget
flutter test test/golden_test.dart                  # regresi visual
flutter test --update-goldens test/golden_test.dart # perbarui acuan visual
```

**89 pengujian**, terdiri atas:

| Berkas | Jumlah | Cakupan |
|---|---|---|
| `widget_test.dart` | 77 | Alur pengguna, navigasi, validasi formulir |
| `golden_test.dart` | 8 | Regresi visual delapan layar utama |
| `assets_test.dart` | 4 | Ketersediaan berkas aset |

### Golden test

Golden test membandingkan hasil render dengan tangkapan layar acuan di
`test/goldens/`. Perubahan tata letak yang tidak tercakup oleh pernyataan
(*assertion*) apa pun tetap akan terdeteksi di sini.

Pendekatan ini terbukti berguna: golden test menemukan empat kerusakan tata
letak yang lolos dari 79 pengujian widget — di antaranya kisi layanan yang
meluap 9,9px, kartu konsultasi yang meluap 49px, dan ilustrasi onboarding yang
bertabrakan dengan judul.

### Catatan pengujian

- Viewport meniru perangkat sungguhan, **lengkap dengan inset bilah status dan
  bilah navigasi gestur**. Tanpa keduanya, bilah navigasi bawah mendapat ruang
  lebih longgar dibanding di perangkat nyata sehingga kerusakan tata letak tidak
  terdeteksi.
- `WidgetController.hitTestWarningShouldBeFatal` diaktifkan: widget yang tidak
  dapat disentuh menggagalkan pengujian, bukan sekadar memberi peringatan.
- Autentikasi memakai `FakeAuthRepository` sehingga pengujian tidak bergantung
  pada jaringan. API rumah sakit berada di jaringan internal; pengujian yang
  gagal saat berada di luar jaringan tidak memberi informasi apa pun tentang
  kualitas kode.
- Fonta menggunakan Ahem di lingkungan pengujian, sehingga huruf tampil sebagai
  kotak. Golden test memverifikasi tata letak, spasi, dan warna — bukan bentuk
  huruf.

---

## Status Pengembangan

### Sudah selesai
- Seluruh layar antarmuka sesuai desain
- Autentikasi tersambung ke API sungguhan (login, registrasi, sesi, keluar)
- Sistem desain: warna, tipografi, spasi, elevasi, motion
- 89 pengujian otomatis

### Masih memakai data contoh
Modul berikut masih menggunakan data statis dan siap disambungkan ke endpoint
yang sudah tersedia di backend:

| Modul | Endpoint yang tersedia |
|---|---|
| Spesialisasi | `GET /api/taptalk/clinics` |
| Daftar dokter | `GET /api/taptalk/doctors` |
| Jadwal praktik | `GET /api/taptalk/schedule` |
| Slot waktu | `GET /api/taptalk/slots` |
| Hari libur | `GET /api/taptalk/holidays` |
| Buat janji temu | `POST /api/taptalk/appointment` |
| Batalkan janji | `POST /api/taptalk/void` |

### Belum tersedia
- Lupa password dan pemulihan akun
- Verifikasi email
- Pencocokan akun aplikasi dengan rekam medis rumah sakit — memerlukan izin
  tulis ke basis data rumah sakit yang saat ini bersifat *read-only*
- Beberapa berkas gambar (`runner.png`, `promo_1..4`, dan beberapa sampul
  artikel) belum tersedia; aplikasi menampilkan *placeholder* bergaya sebagai
  gantinya

---

## Lisensi

Proyek internal Ciputra Hospital Surabaya. Belum ditentukan lisensinya.
