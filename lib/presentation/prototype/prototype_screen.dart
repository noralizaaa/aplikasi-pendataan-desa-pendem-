import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'prototype_controller.dart';

class PrototypeScreen extends GetView<PrototypeController> {
  const PrototypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // Bagian atas dengan clipping khusus kanan bawah melengkung
          ClipPath(
            clipper: BottomRightRoundedClipper(),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9CECFB),
                    Color(0x8015B7B9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isLogoVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      child: Image.asset(
                        'assets/images/bps.png',
                        width: 80,
                      ),
                    )),
                    const SizedBox(height: 20),

                    // Judul
                    const Text(
                      "Selamat Datang di",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Image.asset(
                      'assets/images/SensusKu.png',
                      width: 250,
                    ),
                    const SizedBox(height: 40),

                    // Ilustrasi
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isIllustrationVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      child: Image.asset(
                        'assets/images/undraw_mobile-ux_5h2w.png',
                        width: size.width * 0.8,
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bagian bawah: deskripsi dan tombol START
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // <-- ini bikin konten di tengah vertikal
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // Sedikit lebih tebal dari normal (medium)
                      color: Color(0xFF333333),    // Abu-abu gelap, lebih lembut dari hitam murni
                      letterSpacing: 0.2,          // Sedikit jarak antar huruf untuk keterbacaan
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Aksi saat tombol diklik
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D1A3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "START",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomClipper dengan potongan lengkung di kanan bawah
class BottomRightRoundedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height); // kiri bawah
    path.lineTo(size.width - 150, size.height); // sebelum lengkung, lebih jauh ke kiri
    path.quadraticBezierTo(
      size.width, size.height, // titik kontrol kurva di pojok kanan bawah
      size.width, size.height - 150, // titik akhir lengkung ke atas
    );
    path.lineTo(size.width, 0); // kanan atas
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}