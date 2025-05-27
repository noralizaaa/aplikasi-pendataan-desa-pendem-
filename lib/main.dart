import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'infrastructure/navigation/routes.dart'; // Pastikan AppRoutes dan EnvironmentsBadge ada di sini atau diimpor oleh file ini
import 'presentation/theme/app_theme.dart';

// Jika EnvironmentsBadge tidak ada di dalam 'infrastructure/navigation/routes.dart',
// Anda perlu memastikan ia diimpor atau didefinisikan di sini.
// Misalnya, jika EnvironmentsBadge ada di file terpisah:
// import 'presentation/widgets/environments_badge.dart'; // Contoh path

Future<void> main() async { // Jadikan main() sebagai async
  // Pastikan semua binding Flutter siap sebelum menjalankan kode plugin
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  // Ini harus dilakukan sebelum menjalankan aplikasi dan sebelum menggunakan layanan Firebase lainnya
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Menggunakan konfigurasi dari firebase_options.dart
  );

  initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BPS App',
      theme: AppTheme.lightTheme, // Pastikan AppTheme.lightTheme terdefinisi
      initialRoute: AppRoutes.splash, // Pastikan AppRoutes.splash terdefinisi
      getPages: AppRoutes.routes,     // Pastikan AppRoutes.routes terdefinisi
      builder: (context, child) {
        // Penting untuk menangani kasus di mana child bisa null
        if (child == null) {
          // Anda bisa mengembalikan widget kosong atau loading indicator jika perlu
          return const SizedBox.shrink();
        }
        // Pastikan EnvironmentsBadge terdefinisi dan diimpor dengan benar
        return EnvironmentsBadge(child: child);
      },
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
    );
  }
}
