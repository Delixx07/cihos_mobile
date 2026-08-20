# Prompt: Tambahkan Auth Pasien untuk Aplikasi Mobile

> Salin seluruh isi di bawah garis ini ke AI yang akan mengerjakan backend Laravel.
> Jalankan dari dalam direktori `c:\xampp\htdocs\appointment`.

---

## Konteks Proyek

Kamu bekerja pada aplikasi Laravel 12 (PHP 8.2) di `c:\xampp\htdocs\appointment`.
Ini adalah sistem appointment Ciputra Hospital Surabaya yang **sudah berjalan di
produksi** pada `http://172.20.0.39/appointment`. Jangan merusak fitur yang ada.

Aplikasi ini melayani beberapa klien lewat API dengan guard header `X-Api-Key`:
- `/api/taptalk/*` — bot WhatsApp
- `/api/kiosk/*` — kiosk walk-in di rumah sakit
- `/api/queue/*` — aplikasi antrian

Sekarang ada klien baru: **aplikasi mobile Flutter untuk pasien**. Aplikasi ini
butuh login pasien (email + password) yang **belum tersedia sama sekali**.

### Fakta penting tentang kondisi saat ini

1. **Belum ada endpoint login pasien.** `routes/web.php` punya `AuthController`
   untuk login **admin rumah sakit** lewat form web (session-based, balas HTML
   redirect). Itu bukan untuk pasien dan bukan API. Jangan diubah.

2. **Laravel Sanctum belum terpasang.** Cek `composer.json` — tidak ada
   `laravel/sanctum` maupun `laravel/passport`.

3. **Tabel `patients_app` belum punya kolom password.** Skema saat ini
   (`database/migrations/2026_07_07_100000_create_patients_app_table.php`):

   ```php
   Schema::create('patients_app', function (Blueprint $table) {
       $table->id();
       $table->string('MedicalNo', 50)->unique();
       $table->string('PatientName', 150);
       $table->string('Gender', 20)->nullable();
       $table->date('DOB')->nullable();
       $table->string('MobilePhoneNo', 30)->nullable();
       $table->string('EmailAddress', 150)->nullable();
       $table->string('StreetName', 255)->nullable();
       $table->boolean('IsNewPatient')->default(true);
       $table->timestamps();
   });
   ```

4. **Model `App\Models\AppPatient` masih `extends Model`** (model data biasa),
   belum `Authenticatable`.

5. **Tabel ini ada di koneksi default, bukan DB rumah sakit.** Login DB rumah
   sakit (`itrs2`) bersifat read-only (`db_datareader`), jadi pasien yang dibuat
   lewat aplikasi memang sengaja disimpan lokal. Jangan coba menulis ke DB rumah
   sakit.

   Catatan: komentar di `AppPatient.php` dan di migration menyebut "sqlite",
   tetapi `.env` sebenarnya memakai `DB_CONNECTION=mysql` dengan database
   `appointment_pasien_cihos`. Komentar itu sudah usang — **ikuti `.env`**, dan
   sekalian perbaiki komentar yang menyesatkan itu.

6. **Pola guard API key yang sudah dipakai** ada di
   `app/Http/Controllers/TaptalkController.php` method `guard()`:

   ```php
   protected function guard(Request $request)
   {
       $expected = (string) config($this->apiKeyConfig);
       $given    = (string) $request->header('X-Api-Key', '');
       if ($expected === '' || ! hash_equals($expected, $given)) {
           return response()->json([
               'ok' => false, 'error' => 'unauthorized',
               'message' => 'API key tidak valid.'
           ], 401);
       }
       return null;
   }
   ```

   Key-nya didaftarkan di `config/services.php` (lihat `kiosk`, `taptalk`,
   `antrian`) dan nilainya diambil dari `.env`.

---

## Yang Harus Kamu Kerjakan

### 1. Migration: tambah kolom auth ke `patients_app`

Buat migration **baru** (jangan edit migration lama — tabelnya sudah ada isinya
di produksi). Tambahkan:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `password` | `string(255)` nullable | Hash bcrypt. Nullable karena pasien lama hasil sync belum punya akun. |
| `nik` | `string(16)` nullable, unique | NIK KTP. Dipakai **hanya saat registrasi** untuk mencegah daftar ganda dan mencocokkan pasien lama. |
| `email_verified_at` | `timestamp` nullable | Disiapkan sekarang agar tidak perlu migrasi data nanti. |

Juga: buat `EmailAddress` menjadi **unique**.

**Hati-hati:** kalau di tabel sudah ada baris dengan `EmailAddress` duplikat atau
NULL, penambahan unique index akan gagal. Sebelum menambah index, periksa dulu:

```sql
SELECT EmailAddress, COUNT(*) FROM patients_app
WHERE EmailAddress IS NOT NULL
GROUP BY EmailAddress HAVING COUNT(*) > 1;
```

Kalau ada duplikat, laporkan ke saya dan **berhenti** — jangan menghapus atau
mengubah data pasien sendiri.

Koneksi default adalah **MySQL** (`appointment_pasien_cihos`), jadi
`$table->unique('EmailAddress')` di migration baru sudah cukup — tidak perlu
`doctrine/dbal`.

### 2. Ubah `AppPatient` menjadi Authenticatable

File: `app/Models/AppPatient.php`

- `extends Illuminate\Foundation\Auth\User as Authenticatable`
- `use Laravel\Sanctum\HasApiTokens`
- Tambahkan `password`, `nik`, `EmailAddress` ke `$fillable`
- `protected $hidden = ['password', 'remember_token'];` — **wajib**, supaya hash
  password tidak pernah bocor ke response JSON
- `protected $casts` tambahkan `'password' => 'hashed'` — Laravel akan hash
  otomatis saat assign, jangan hash manual dua kali
- Karena kolom email bernama `EmailAddress` (bukan `email`), override:
  ```php
  public function getAuthIdentifierName() { return 'EmailAddress'; }
  ```

Pertahankan komentar dokumentasi yang sudah ada di file itu.

### 3. Pasang Sanctum

```bash
composer require laravel/sanctum
php artisan install:api
```

Pastikan migration `personal_access_tokens` ikut jalan. Alasan pakai token dan
bukan session: klien adalah aplikasi mobile, tidak punya cookie jar yang andal,
dan token bisa dicabut per-perangkat kalau HP hilang.

### 4. API key khusus mobile

Tambahkan di `config/services.php`, mengikuti pola yang sudah ada:

```php
// Shared secret untuk aplikasi mobile pasien (/api/app/*).
// Aplikasi Flutter mengirimnya sebagai header X-Api-Key.
'mobile' => [
    'api_key' => env('MOBILE_API_KEY'),
],
```

Tambahkan `MOBILE_API_KEY=` ke `.env.example`. **Jangan** tulis nilai key
sungguhan ke file mana pun yang ikut ter-commit — saya yang akan mengisi `.env`.

**Penting:** buat key baru khusus mobile, jangan pakai ulang `TAPTALK_API_KEY`
atau `KIOSK_API_KEY`. Kedua key itu punya hak membuat dan membatalkan janji atas
nama sistem lain; kalau bocor dari APK, bisa disalahgunakan.

### 5. Endpoint baru

Buat `app/Http/Controllers/Api/AppAuthController.php`. Daftarkan di
`routes/api.php` dalam grup yang dilindungi API key + throttle, mengikuti pola
grup yang sudah ada.

Semua endpoint di bawah **wajib** menyertakan header `X-Api-Key: <MOBILE_API_KEY>`.

#### `POST /api/app/register`

Body:
```json
{
  "name": "Nadila Putri",
  "email": "nadila@example.com",
  "password": "rahasia123",
  "password_confirmation": "rahasia123",
  "nik": "3578012345670001",
  "phone": "081234567890",
  "dob": "1998-05-14",
  "gender": "Perempuan"
}
```

Validasi:
- `email` — wajib, format email, `unique:patients_app,EmailAddress`
- `password` — wajib, min 8 karakter, `confirmed`
- `nik` — wajib, tepat 16 digit angka, `unique:patients_app,nik`
- `name` — wajib, max 150
- `phone` — wajib, max 30
- `dob` — wajib, format tanggal, harus di masa lalu

Perilaku:
- `MedicalNo` di-generate (tabel mensyaratkan unique dan NOT NULL). Saya sudah
  memeriksa: **belum ada helper generator** di proyek ini, jadi kamu perlu
  membuatnya. Pakai pola berprefix yang jelas menandai asal-usulnya, misal
  `APP-000012`, supaya mudah dibedakan dari nomor rekam medis asli rumah sakit.
  Pastikan aman dari race condition (dua registrasi bersamaan tidak boleh dapat
  nomor sama) — gunakan transaksi atau andalkan unique constraint + retry.
- `IsNewPatient` = true
- Balas **201** dengan token dan data pasien

#### `POST /api/app/login`

Body:
```json
{ "email": "nadila@example.com", "password": "rahasia123" }
```

Perilaku:
- Cari berdasarkan `EmailAddress`
- Verifikasi dengan `Hash::check()`
- **Jangan** bedakan pesan error antara "email tidak ada" dan "password salah" —
  keduanya balas pesan sama, supaya tidak bisa dipakai menebak email terdaftar
- Kalau `password` NULL (pasien lama hasil sync, belum punya akun), tolak dengan
  pesan yang mengarahkan untuk registrasi
- Berhasil → **200** dengan token
- Gagal → **401**

Tambahkan rate limit pada endpoint login (misal 5 percobaan per menit per IP)
untuk menahan brute force.

#### `GET /api/app/me`

Header: `X-Api-Key` + `Authorization: Bearer <token>`. Balas data pasien yang
sedang login. Dipakai aplikasi saat dibuka untuk cek token masih valid.

#### `POST /api/app/logout`

Cabut token yang sedang dipakai (`$request->user()->currentAccessToken()->delete()`).

### 6. Bentuk response

Ikuti persis konvensi yang sudah dipakai controller lain di proyek ini —
`{"ok": true, ...}` untuk sukses, `{"ok": false, "error": "...", "message": "..."}`
untuk gagal. Pesan dalam **Bahasa Indonesia**.

Sukses login/register:
```json
{
  "ok": true,
  "token": "1|abcdef...",
  "patient": {
    "id": 12,
    "medical_no": "APP-000012",
    "name": "Nadila Putri",
    "email": "nadila@example.com",
    "phone": "081234567890",
    "dob": "1998-05-14",
    "gender": "Perempuan",
    "is_new_patient": true
  }
}
```

Gagal login:
```json
{ "ok": false, "error": "invalid_credentials", "message": "Email atau password salah." }
```

Gagal validasi → **422**:
```json
{
  "ok": false,
  "error": "validation_failed",
  "message": "Data yang dikirim tidak valid.",
  "errors": { "email": ["Email sudah terdaftar."] }
}
```

**Password dan hash-nya tidak boleh muncul di response mana pun.**

---

## Aturan Kerja

1. **Ini aplikasi produksi.** Jangan ubah endpoint, controller, atau migration
   yang sudah ada kecuali diminta di atas. Khususnya jangan sentuh
   `AuthController` (login admin web), `TaptalkController`, `KioskController`.

2. **Jangan tulis nilai secret ke file.** `MOBILE_API_KEY` cukup ditambahkan
   sebagai baris kosong di `.env.example`.

3. **Jangan ubah atau hapus data pasien yang sudah ada.** Kalau migration
   terhalang data duplikat, laporkan dan berhenti.

4. Setelah selesai, jalankan `php artisan route:list --path=api/app` dan
   tunjukkan hasilnya, supaya saya bisa memastikan route-nya benar terdaftar.

5. Tunjukkan juga contoh perintah `curl` untuk menguji register dan login.

6. Kalau ada keputusan yang ambigu (misal pola `MedicalNo`), tanya dulu — jangan
   asal pilih.

---

## Yang TIDAK perlu dikerjakan sekarang

- Reset password / lupa password
- Verifikasi email lewat kirim email
- Mencocokkan akun aplikasi dengan rekam medis asli di DB rumah sakit — ini butuh
  izin tulis yang belum ada, dan keputusannya ada di IT rumah sakit
- Mengubah endpoint `/api/taptalk/*` atau `/api/kiosk/*`
