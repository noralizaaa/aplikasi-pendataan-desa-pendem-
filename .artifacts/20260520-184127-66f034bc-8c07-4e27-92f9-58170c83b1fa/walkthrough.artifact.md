# Walkthrough - Implementasi Role `admindesa`

Saya telah mengimplementasikan role baru `admindesa` yang memungkinkan pengelolaan data terbatas pada wilayah desa masing-masing.

## Perubahan Utama

### 1. Model Data
- **`AuthUser` & `AdminAccountModel`**: Ditambahkan field `villageId` dan `villageName` untuk menyimpan identitas desa user yang sedang login.
- **`FormSubmission`**: Ditambahkan field `villageId` dan `villageName`. Setiap data yang dikirim sekarang mencatat ID desa pengirim agar dapat difilter di dashboard admin.

### 2. Alur Login & Splash
- **`LoginController` & `SplashController`**: Sekarang mengenali role `admindesa` dan mengizinkan mereka masuk ke halaman Admin (`AppRoutes.adminPage`). Data desa (village) diambil dari Firestore saat login dan disimpan dalam state aplikasi.

### 3. Dashboard Admin (`AdminController`)
- Menambahkan logika filter. Jika user yang login adalah `admindesa`, query ke Firestore untuk statistik dashboard akan difilter berdasarkan `villageId` user tersebut.

### 4. Daftar Isian (`SubmissionsFormController`)
- Filter otomatis diterapkan pada daftar submissions. `admindesa` hanya akan melihat dan dapat mengelola (edit/hapus/ekspor) data yang memiliki `villageId` yang sama dengan mereka.

### 5. Manajemen Akun (`AllAccountController`)
- **Filter Daftar Akun**: `admindesa` hanya bisa melihat daftar akun yang berada di desanya sendiri.
- **Pembuatan Akun Baru**: Jika `admindesa` membuat akun baru (user/admin), sistem akan otomatis mengisi `villageId` dan `villageName` akun baru tersebut sesuai dengan desa sang pembuat.

## Cara Menggunakan
Untuk memberikan akses `admindesa` kepada user:
1. Buka koleksi `users` di Firestore.
2. Cari user yang diinginkan.
3. Ubah field `role` menjadi `admindesa`.
4. Pastikan field `villageId` dan `villageName` sudah terisi dengan ID dan nama desa yang sesuai.

## Verifikasi Teknis
- Memastikan semua import yang diperlukan (seperti `firebase_auth`) sudah ditambahkan.
- Memastikan field baru sudah terdaftar di constructor model dan metode `toFirestore`/`fromFirestore`.
- Validasi kode menggunakan `analyze_file` untuk memastikan tidak ada undefined references.
