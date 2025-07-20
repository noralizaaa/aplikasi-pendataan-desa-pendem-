import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Diperlukan untuk mintaIzinAksesFileNonMedia
import 'dart:io'; // Hanya jika Anda menggunakan kelas File di main.dart, jika tidak, ini untuk fungsi contoh

import 'infrastructure/navigation/routes.dart';
import 'presentation/theme/app_theme.dart';

// Jika EnvironmentsBadge ada di file terpisah:
// import 'presentation/widgets/environments_badge.dart'; // Contoh path

/// Fungsi untuk meminta izin akses file non-media di Android.
/// Untuk platform selain Android, fungsi ini akan melewati permintaan izin.
///
/// Returns [true] jika izin diberikan, [false] jika ditolak atau tidak relevan.
Future<bool> mintaIzinAksesFileNonMedia() async {
  // Cek apakah platform adalah Android
  if (!Platform.isAndroid) {
    print('Platform bukan Android, melewati proses izin file non-media.');
    return true;
  }

  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt ?? 0;
    print('Versi SDK Android: $sdkInt');

    PermissionStatus status;

    if (sdkInt >= 30) {
      print('Memeriksa izin MANAGE_EXTERNAL_STORAGE untuk Android 11+');
      status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
    } else {
      print('Memeriksa izin STORAGE untuk Android < 11');
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (status.isGranted) {
      print('Izin diberikan.');
      return true;
    } else if (status.isPermanentlyDenied) {
      print('Izin ditolak permanen. Membuka pengaturan aplikasi...');
      await openAppSettings();
      return false;
    } else {
      print('Izin ditolak atau belum diberikan. Status: $status');
      return false;
    }
  } catch (e) {
    print('Gagal memeriksa versi Android atau meminta izin: $e');
    return false;
  }
}


void main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode plugin
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GetStorage.init();


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