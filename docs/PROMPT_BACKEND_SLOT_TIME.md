
---

## Permintaan tambahan (opsional, tapi membantu)

Kalau memungkinkan, sertakan **`slot_time`** juga pada respons
`GET /api/app/appointments` (daftar janji temu). Sekarang aplikasi hanya
menerima `date` dan `time` sesi, sehingga pada layar Jadwal Temu kami belum
bisa menampilkan jam yang dijanjikan ke pasien.

---

## Kalau ternyata slot memang tidak punya jam

Mohon konfirmasi bila nomor antrean sebenarnya **murni urutan panggil** —
semua pasien datang di awal sesi dan dipanggil berurutan, tanpa jadwal jam per
pasien.

Kalau begitu keadaannya, permintaan "slot terdekat dari jam sekarang" menjadi
tidak relevan, dan yang kami butuhkan cukup: **backend memilihkan nomor
antrean berikutnya yang tersedia** (tetap `slot_no` opsional). Aplikasi akan
menampilkan jam sesi saja tanpa menjanjikan jam per pasien.

Kami perlu tahu ini supaya tidak menampilkan jam yang tidak pernah dijanjikan
rumah sakit.
