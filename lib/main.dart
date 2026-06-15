import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; 
import 'dart:io'; 

import 'infrastructure/navigation/routes.dart';
import 'presentation/theme/app_theme.dart';

/// Meminta izin akses file non-media pada perangkat Android.
/// 
/// Fungsi ini menangani perbedaan antara versi Android:
/// - Android 11+ (API 30): Meminta izin [MANAGE_EXTERNAL_STORAGE].
/// - Android < 11: Meminta izin [STORAGE] biasa.
/// 
/// Mengembalikan [true] jika izin diberikan, dan [false] jika ditolak atau terjadi kesalahan.
Future<bool> mintaIzinAksesFileNonMedia() async {
  if (!Platform.isAndroid) {
    debugPrint('Platform bukan Android, melewati proses izin file non-media.');
    return true;
  }

  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;
    debugPrint('Versi SDK Android: $sdkInt');

    PermissionStatus status;

    if (sdkInt >= 30) {
      debugPrint('Memeriksa izin MANAGE_EXTERNAL_STORAGE untuk Android 11+');
      status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
    } else {
      debugPrint('Memeriksa izin STORAGE untuk Android < 11');
      status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    if (status.isGranted) {
      debugPrint('Izin diberikan.');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('Izin ditolak permanen. Membuka pengaturan aplikasi...');
      await openAppSettings();
      return false;
    } else {
      debugPrint('Izin ditolak atau belum diberikan. Status: $status');
      return false;
    }
  } catch (e) {
    debugPrint('Gagal memeriksa versi Android atau meminta izin: $e');
    return false;
  }
}

/// Titik masuk utama (Entry Point) aplikasi.
/// 
/// Melakukan inisialisasi layanan penting:
/// 1. Binding Flutter UI.
/// 2. Lokalisasi format tanggal (id_ID).
/// 3. Inisialisasi Firebase Core.
/// 4. Inisialisasi Local Storage (GetStorage).
/// 5. Permintaan izin sistem (Storage).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi lokalisasi untuk format tanggal dan waktu Indonesia
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase dengan opsi sesuai platform saat ini
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi plugin penyimpanan lokal
  await GetStorage.init();

  // Memulai proses permintaan izin akses penyimpanan untuk ekspor file
  debugPrint('Memulai proses permintaan izin akses file non-media...');
  bool izinDiberikan = await mintaIzinAksesFileNonMedia();

  if (izinDiberikan) {
    debugPrint('Izin akses file non-media telah diberikan. Aplikasi dapat melanjutkan.');
  } else {
    debugPrint('Izin akses file non-media tidak diberikan. Beberapa fitur mungkin tidak berfungsi.');
  }

  runApp(const MyApp());
}

/// [MyApp] adalah widget akar (root) aplikasi SensusKu.
/// 
/// Widget ini mengonfigurasi:
/// - Judul Aplikasi.
/// - Tema Global ([AppTheme]).
/// - Sistem Navigasi ([GetMaterialApp]).
/// - Rute awal (Splash Screen).
/// - Daftar seluruh rute aplikasi yang tersedia.
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

/// [EnvironmentsBadge] adalah widget pembungkus yang dapat digunakan untuk 
/// menampilkan indikator status lingkungan (seperti Dev, Staging, Prod) 
/// pada antarmuka aplikasi.
class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
      ],
    );
  }
}
