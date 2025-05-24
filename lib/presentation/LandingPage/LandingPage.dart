import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'LandingPage_controller.dart'; // Pastikan controller ini ada dan benar
// Impor AppRoutes Anda untuk mengakses konstanta rute login
import '../../infrastructure/navigation/routes.dart'; // PASTIKAN PATH INI BENAR

class LandingPageScreen extends GetView<LandingPageController> {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas dengan clipping khusus dan gradien
          ClipPath(
            clipper: BottomRightRoundedClipper(),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9CECFB),
                    Color(0xFF64B5F6),
                    Color(0xFF15B7B9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 30.0,
                  left: 24.0,
                  right: 24.0,
                  bottom: 70.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isLogoVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Image.asset(
                        'assets/images/bps.png', // PASTIKAN PATH ASET INI BENAR
                        width: mediaSize.width * 0.22,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 70, color: Colors.white70),
                      ),
                    )),
                    const SizedBox(height: 20),

                    // Judul
                    const Text(
                      "Selamat Datang di",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black38)
                          ]
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/images/SensusKu.png', // PASTIKAN PATH ASET INI BENAR
                      width: mediaSize.width * 0.7,
                      errorBuilder: (context, error, stackTrace) =>
                      const Text("SensusKu", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 35),

                    // Ilustrasi
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isIllustrationVisible.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeIn,
                      child: Image.asset(
                        'assets/images/undraw_mobile-ux_5h2w.png', // PASTIKAN PATH ASET INI BENAR
                        width: mediaSize.width * 0.75,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(height: mediaSize.width * 0.5, child: const Center(child: Icon(Icons.image_not_supported, size: 90, color: Colors.white70))),
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    "Aplikasi Pendataan dan Pengelolaan Desa\noleh BPS Kota Batu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: mediaSize.width * 0.85,
                    child: ElevatedButton(
                      onPressed: () {
                        // Aksi saat tombol diklik: Navigasi ke halaman login
                        print('Tombol START ditekan, navigasi ke ${AppRoutes.login}...');
                        Get.toNamed(AppRoutes.login);
                        // Pertimbangkan Get.offNamed(AppRoutes.login); jika Anda tidak ingin
                        // pengguna bisa kembali ke LandingPage dari halaman Login dengan tombol back.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: Colors.greenAccent.withOpacity(0.5),
                      ),
                      child: const Text(
                        "START",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 20),
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
    double curveHeight = 80.0;

    path.lineTo(0, size.height - curveHeight);
    path.quadraticBezierTo(0, size.height, curveHeight / 2, size.height);
    path.lineTo(size.width - (curveHeight / 2), size.height);

    path.quadraticBezierTo(
        size.width, size.height,
        size.width, size.height - curveHeight
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}