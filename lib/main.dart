import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Diperlukan untuk mintaIzinAksesFileNonMedia
import 'dart:io'; // Hanya jika Anda menggunakan kelas File di main.dart, jika tidak, ini untuk fungsi contoh

import 'infrastructure/navigation/routes.dart';
import 'presentation/theme/app_theme.dart';

// Jika EnvironmentsBadge ada di file terpisah:
// import 'presentation/widgets/environments_badge.dart'; // Contoh path

// Fungsi untuk meminta izin akses file non-media
// Anda bisa menempatkan ini di sini atau di file helper terpisah dan mengimpornya.
Future<bool> mintaIzinAksesFileNonMedia() async {
  PermissionStatus status;
  AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
  int sdkInt = androidInfo.version.sdkInt;

  print('Versi SDK Android: $sdkInt');

  if (sdkInt >= 30) { // Android 11 (API 30) atau lebih baru
    print('Memeriksa izin MANAGE_EXTERNAL_STORAGE untuk Android 11+');
    // Penting: Pertama cek statusnya, jangan langsung request jika sudah granted.
    status = await Permission.manageExternalStorage.status;
    print('Status MANAGE_EXTERNAL_STORAGE awal: $status');
    if (!status.isGranted) {
      // PERINGATAN: Meminta MANAGE_EXTERNAL_STORAGE akan mengarahkan pengguna
      // ke halaman pengaturan sistem. Ini bukan dialog popup biasa.
      status = await Permission.manageExternalStorage.request();
      print('Status MANAGE_EXTERNAL_STORAGE setelah request (dari halaman pengaturan): $status');
    }
  } else { // Android 10 (API 29) atau lebih lama (hingga Nougat API 24)
    print('Memeriksa izin STORAGE untuk Android < 11');
    status = await Permission.storage.status;
    print('Status STORAGE awal: $status');
    if (!status.isGranted) {
      status = await Permission.storage.request();
      print('Status STORAGE setelah request: $status');
    }
  }

  if (status.isGranted) {
    print('Izin yang relevan diberikan.');
    return true;
  } else if (status.isPermanentlyDenied) {
    // Jika ditolak permanen, selalu baik untuk menawarkan membuka pengaturan.
    print('Izin ditolak permanen. Membuka pengaturan aplikasi...');
    await openAppSettings();
    return false;
  } else if (sdkInt >= 30 && status.isDenied) {
    // Untuk MANAGE_EXTERNAL_STORAGE, status 'isDenied' setelah request() sering berarti
    // pengguna keluar dari halaman pengaturan tanpa memberikan izin.
    // Atau pengguna menolak di dialog konfirmasi sebelum ke halaman pengaturan (jika ada).
    print('Izin MANAGE_EXTERNAL_STORAGE ditolak (mungkin dari halaman pengaturan). Pertimbangkan untuk membuka pengaturan.');
    // Anda bisa memilih untuk memanggil openAppSettings() di sini juga,
    // atau memberikan pesan lain kepada pengguna.
    // await openAppSettings(); // Opsional, tergantung UX yang diinginkan
    return false;
  }
  else {
    print('Izin ditolak (status: $status).');
    return false;
  }
}


Future<void> main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode plugin
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- AWAL BLOK PERMINTAAN IZIN PENYIMPANAN ---
  // Mengganti blok izin lama dengan panggilan ke fungsi baru
  print('Memulai proses permintaan izin akses file non-media...');
  bool izinDiberikan = await mintaIzinAksesFileNonMedia();

  if (izinDiberikan) {
    print('Izin akses file non-media telah diberikan. Aplikasi dapat melanjutkan.');
    // Anda bisa melakukan tindakan lain di sini jika izin diberikan,
    // misalnya memuat data dari file atau mengaktifkan fitur tertentu.
  } else {
    print('Izin akses file non-media tidak diberikan. Beberapa fitur mungkin tidak berfungsi.');
    // Tangani kasus di mana izin tidak diberikan. Anda mungkin ingin menampilkan
    // pesan kepada pengguna atau menonaktifkan fitur yang memerlukan izin ini.
  }
  // --- AKHIR BLOK PERMINTAAN IZIN PENYIMPANAN ---

  // Panggilan initializeDateFormatting() kedua ini mungkin tidak diperlukan
  // initializeDateFormatting(); // Tinjau apakah panggilan ini masih dibutuhkan

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BPS App',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        return EnvironmentsBadge(child: child);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
      ],
    );
  }
}

// Contoh penggunaan fungsi bacaFileContohSetelahIzin (TIDAK dipanggil di main() secara default)
// Ini hanya untuk menunjukkan bagaimana Anda akan menggunakan izin tersebut nanti.
// Anda akan memanggil fungsi seperti ini dari bagian lain aplikasi Anda ketika
// Anda benar-benar perlu membaca file tertentu.
/*
Future<void> bacaFileContohSetelahIzin(String pathFile) async {
  // Cek ulang izin sebelum operasi file, atau andalkan status dari startup
  bool punyaIzin = await mintaIzinAksesFileNonMedia(); // Atau simpan status dari `main`

  if (punyaIzin) {
    try {
      final file = File(pathFile); // Contoh: /storage/emulated/0/Download/dataku.csv
      if (await file.exists()) {
        String konten = await file.readAsString();
        print('Berhasil membaca file: ${file.path}');
        // Lakukan sesuatu dengan konten
      } else {
        print('File tidak ditemukan di path: ${file.path}');
      }
    } catch (e) {
      print('Error membaca file: $e');
    }
  } else {
    print('Tidak mendapatkan izin untuk membaca file.');
  }
}
*/