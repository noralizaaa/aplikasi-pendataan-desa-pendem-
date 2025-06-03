import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'LandingPage_controller.dart'; // Pastikan controller ini ada
// Impor AppRoutes Anda untuk mengakses konstanta rute login
import '../../infrastructure/navigation/routes.dart'; // PASTIKAN PATH INI BENAR

// CustomClipper yang sudah disesuaikan agar lengkungan lebih ke bawah
class BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double curveHeight = 50.0; // "Bahu" lengkungan sedikit lebih rendah

    path.lineTo(0, size.height - curveHeight);

    // Titik kontrol Y disesuaikan agar lengkungan lebih dalam
    double controlPointY = size.height + curveHeight / 1.8;

    path.quadraticBezierTo(
      size.width / 2,
      controlPointY,
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
    final Size mediaSize = MediaQuery.of(context).size;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double bottomPaddingForClipPathContent = 50.0;

    final double supporterLogoWidth = mediaSize.width * 0.12;
    final double supporterLogoHeight = mediaSize.width * 0.12;


    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bagian atas dengan clipping (AREA ORANYE)
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
                          bottom: bottomPaddingForClipPathContent,
                        ),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(() => AnimatedOpacity(
                                opacity: controller.isLogoVisible.value ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 800),
                                child: Image.asset(
                                  'assets/images/bps.png',
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
                                'assets/images/SensusKu.png',
                                width: mediaSize.width * 0.65,
                                errorBuilder: (context, error, stackTrace) =>
                                const Text("SensusKu", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              const SizedBox(height: 20),
                              Obx(() => AnimatedOpacity(
                                opacity: controller.isIllustrationVisible.value ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeIn,
                                child: Image.asset(
                                    'assets/images/undraw_mobile-ux_5h2w.png',
                                    width: mediaSize.width * 0.60, // USER CHANGED THIS
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      print("Error loading undraw_mobile-ux_5h2w.png: $error");
                                      return SizedBox(height: mediaSize.width * 0.1);
                                    }
                                ),
                              )),
                              const SizedBox(height: 50), // USER CHANGED THIS

                              // Bagian "Didukung Oleh" dan Logo Pendukung (dibungkus Container)
                              Obx(() => AnimatedOpacity(
                                opacity: controller.isIllustrationVisible.value ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeIn,
                                child: Column(
                                  children: [
                                    const Text(
                                      "Supported by:",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(offset: Offset(0.5, 0.5), blurRadius: 1.0, color: Colors.black26)
                                          ]
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    // Container pembungkus untuk logo pendukung
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      decoration: BoxDecoration(
                                        // Warna latar belakang yang sedikit berbeda untuk grouping
                                        // Misalnya, putih dengan sedikit opacity atau abu-abu sangat muda
                                        color: Colors.white.withOpacity(0.16), // Contoh: semi-transparan
                                        borderRadius: BorderRadius.circular(12.0),
                                        // Optional: tambahkan border jika diinginkan
                                        // border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/bps.png',
                                            width: supporterLogoWidth,
                                            height: supporterLogoHeight,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.broken_image, size: supporterLogoHeight * 0.8, color: Colors.white70),
                                          ),
                                          Image.asset(
                                            'assets/images/pemkotbatu.png',
                                            width: supporterLogoWidth,
                                            height: supporterLogoHeight,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.broken_image, size: supporterLogoHeight * 0.8, color: Colors.white70),
                                          ),
                                          Image.asset(
                                            'assets/images/Umm.png',
                                            width: supporterLogoWidth,
                                            height: supporterLogoHeight,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.broken_image, size: supporterLogoHeight * 0.8, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bagian bawah: deskripsi dan tombol START
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle( // Default style untuk paragraf
                          fontSize: 14,
                          color: Color(0xFF555555), // Sedikit lebih lembut dari abu-abu murni
                          height: 1.6,
                          fontFamily: 'Roboto', // Ganti dengan font pilihan Anda jika ada
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: "SENSUSKU\n",
                            style: TextStyle(
                              fontSize: 18, // Lebih besar
                              fontWeight: FontWeight.bold, // Tebal
                              color: Colors.orangeAccent.shade700, // Warna biru tua (sesuaikan dengan tema BPS atau aplikasi)
                              letterSpacing: 0.5, // Sedikit jarak antar huruf
                            ),
                          ),
                          const TextSpan(
                            text: "Sistem Entri dan Survei untuk Statistik Desa/Kelurahan",
                          ),
                        ],
                      ),
                    ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: mediaSize.width * 0.85,
                          child: ElevatedButton(
                            onPressed: () {
                              print('Tombol START ditekan, navigasi ke ${AppRoutes.login}...');
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
