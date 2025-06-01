import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'LandingPage_controller.dart'; // Pastikan controller ini ada dan sudah diperbaiki
// Impor AppRoutes Anda untuk mengakses konstanta rute login
import '../../infrastructure/navigation/routes.dart'; // PASTIKAN PATH INI BENAR

// CustomClipper baru untuk bentuk seperti di Figma
class BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double curveHeight = 60.0; // Tinggi lengkungan

    path.lineTo(0, size.height - curveHeight);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + curveHeight / 2.5, // Titik kontrol untuk lengkungan ke bawah
      size.width,
      size.height - curveHeight,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LandingPageScreen extends GetView<LandingPageController> {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller jika belum ada (karena tidak pakai binding)
    // GetX akan otomatis membuat instance jika belum ada saat GetView ini dibangun.
    // final controller = Get.put(LandingPageController()); // Opsional jika ingin kontrol lebih atau akses di luar GetView

    final Size mediaSize = MediaQuery.of(context).size;
    // Estimasi tinggi status bar, bisa bervariasi
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas dengan clipping
          ClipPath(
            clipper: BottomArcClipper(),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEDDAB), Color(0xFFF39C12)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: statusBarHeight + 15.0,
                  left: 24.0,
                  right: 24.0,
                  bottom: 110.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isLogoVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Image.asset(
                        'assets/images/bps.png', // PASTIKAN ASSET INI ADA & TERDAFTAR
                        width: mediaSize.width * 0.20,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 60, color: Colors.white70),
                      ),
                    )),
                    const SizedBox(height: 15),
                    const Text(
                      "Selamat Datang di",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(1.0, 1.0), blurRadius: 2.0, color: Colors.black26)
                          ]),
                    ),
                    const SizedBox(height: 5),
                    Image.asset(
                      'assets/images/SensusKu.png', // PASTIKAN ASSET INI ADA & TERDAFTAR
                      width: mediaSize.width * 0.65,
                      errorBuilder: (context, error, stackTrace) =>
                      const Text("SensusKu", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 70),
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isIllustrationVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeIn,
                      child: Image.asset(
                        'assets/images/undraw_mobile-ux_5h2w.png', // PASTIKAN ASSET INI ADA & TERDAFTAR
                        width: mediaSize.width * 0.70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            SizedBox(height: mediaSize.width * 0.4, child: const Center(child: Icon(Icons.image_not_supported, size: 70, color: Colors.white70))),
                      ),
                    )),
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Aplikasi Pendataan dan Pengelolaan Desa\noleh BPS Kota Batu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: mediaSize.width * 0.85,
                    child: ElevatedButton(
                      onPressed: () {
                        print('Tombol START ditekan, navigasi ke ${AppRoutes.login}...');
                        // PASTIKAN AppRoutes.login SUDAH BENAR DIDEFINISIKAN
                        Get.toNamed(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF37B00),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        elevation: 4,
                        shadowColor: Colors.orangeAccent.withOpacity(0.3),
                      ),
                      child: const Text(
                        "START",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}