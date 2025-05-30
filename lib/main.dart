import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:permission_handler/permission_handler.dart'; // Pastikan ini diimpor

import 'infrastructure/navigation/routes.dart';
import 'presentation/theme/app_theme.dart';

// Jika EnvironmentsBadge tidak ada di dalam 'infrastructure/navigation/routes.dart',
// Anda perlu memastikan ia diimpor atau didefinisikan di sini.
// Misalnya, jika EnvironmentsBadge ada di file terpisah:
// import 'presentation/widgets/environments_badge.dart'; // Contoh path

Future<void> main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan kode plugin
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- AWAL BLOK PERMINTAAN IZIN PENYIMPANAN ---
  // Meminta izin penyimpanan saat aplikasi dimulai
  var statusPenyimpanan = await Permission.storage.request();
  print('Status Izin Penyimpanan Awal: $statusPenyimpanan');

  if (statusPenyimpanan.isDenied) {
    // Pengguna menolak izin, Anda bisa menampilkan pesan atau mencoba meminta lagi nanti
    print('Izin penyimpanan ditolak.');
  } else if (statusPenyimpanan.isPermanentlyDenied) {
    // Pengguna menolak izin secara permanen, arahkan ke pengaturan aplikasi
    print('Izin penyimpanan ditolak permanen. Membuka pengaturan aplikasi...');
    await openAppSettings();
  } else if (statusPenyimpanan.isGranted) {
    // Izin diberikan
    print('Izin penyimpanan diberikan.');
  }
  // --- AKHIR BLOK PERMINTAAN IZIN PENYIMPANAN ---

  // Inisialisasi format tanggal (panggilan kedua ini mungkin bisa ditinjau apakah masih diperlukan
  // jika yang pertama dengan 'id_ID' sudah mencakup)
  initializeDateFormatting();

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
        // Pastikan EnvironmentsBadge terdefinisi dan diimpor dengan benar
        // Jika EnvironmentsBadge tidak ada, Anda bisa menghapus widget ini
        // atau menggantinya dengan child secara langsung.
        // Contoh: return child;
        return EnvironmentsBadge(child: child);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Anda mungkin perlu membuat atau memastikan widget EnvironmentsBadge ada.
// Jika belum ada, berikut contoh placeholder sederhananya:
class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementasi sederhana, Anda bisa menyesuaikannya
    // atau menghapus penggunaannya jika tidak diperlukan.
    return Stack(
      children: [
        child,
        // Contoh badge, bisa dihilangkan jika tidak perlu
        // Positioned(
        //   top: 10,
        //   right: 10,
        //   child: Container(
        //     padding: EdgeInsets.all(5),
        //     color: Colors.red,
        //     child: Text("DEV", style: TextStyle(color: Colors.white, fontSize: 10)),
        //   ),
        // )
      ],
    );
  }
}
