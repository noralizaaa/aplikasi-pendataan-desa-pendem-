import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'LandingPage_controller.dart'; // Pastikan controller ini ada dan benar
// Impor AppRoutes Anda untuk mengakses konstanta rute login
import '../../infrastructure/navigation/routes.dart'; // PASTIKAN PATH INI BENAR

// CustomClipper baru untuk bentuk seperti di Figma
class BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double curveHeight = 60.0; // Anda bisa menyesuaikan nilai ini untuk kedalaman lengkungan

    path.lineTo(0, size.height - curveHeight); // Mulai dari kiri, sedikit di atas titik terendah lengkungan
    path.quadraticBezierTo(
      size.width / 2, // Titik kontrol X di tengah
      size.height + curveHeight / 2.5, // Titik kontrol Y di bawah batas bawah container untuk membuat lengkungan ke bawah
      size.width, // Titik akhir X di kanan
      size.height - curveHeight, // Titik akhir Y di kanan, sama tingginya dengan awal
    );
    path.lineTo(size.width, 0); // Garis ke pojok kanan atas
    path.lineTo(0, 0); // Garis ke pojok kiri atas
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas dengan clipping khusus dan gradien
          ClipPath(
            clipper: BottomArcClipper(), // Menggunakan clipper baru
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFEDDAB), // Warna oranye muda (sesuaikan jika perlu)
                    Color(0xFFF39C12), // Warna oranye lebih tua (sesuaikan jika perlu)
                  ],
                  begin: Alignment.topCenter, // Gradien dari atas ke bawah
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 30.0,
                  left: 24.0,
                  right: 24.0,
                  // Sesuaikan padding bawah agar konten tidak terlalu dekat dengan lengkungan
                  // Mungkin perlu dikurangi sedikit karena lengkungan sekarang berbeda
                  bottom: 80.0, // Anda mungkin perlu menyesuaikan nilai ini
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
                            Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.black26) // Shadow sedikit lebih lembut
                          ]),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/images/SensusKu.png', // PASTIKAN PATH ASET INI BENAR
                      // Jika SensusKu.png berwarna putih, Anda mungkin memerlukan aset gambar dengan teks oranye
                      // atau menggunakan widget Text dengan style oranye.
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
                        // Ganti dengan path ilustrasi yang sesuai dengan desain Figma (ilustrasi orang dan HP)
                        'assets/images/undraw_mobile-ux_5h2w.png', // GANTI JIKA PERLU SESUAI FIGMA
                        width: mediaSize.width * 0.75,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(height: mediaSize.width * 0.5, child: const Center(child: Icon(Icons.image_not_supported, size: 90, color: Colors.white70))),
                      ),
                    )),
                    const SizedBox(height: 24), // Mungkin perlu disesuaikan lagi dengan padding bottom
                  ],
                ),
              ),
            ),
          ),

          // Bagian bawah: deskripsi dan tombol START
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white, // Latar belakang putih untuk bagian bawah
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(), // Mendorong konten ke tengah vertikal jika ruang lebih
                  const Text(
                    "Aplikasi Pendataan dan Pengelolaan Desa\noleh BPS Kota Batu",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242), // Abu-abu tua untuk teks deskripsi
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: mediaSize.width * 0.85,
                    child: ElevatedButton(
                      onPressed: () {
                        print('Tombol START ditekan, navigasi ke ${AppRoutes.login}...');
                        Get.toNamed(AppRoutes.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF37B00), // Warna oranye untuk tombol
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        elevation: 5,
                        shadowColor: Colors.orangeAccent.withOpacity(0.4), // Bayangan oranye
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
                  const Spacer(), // Mendorong konten ke tengah vertikal
                  const SizedBox(height: 20), // Sedikit ruang di bagian paling bawah
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Komentar untuk clipper lama jika Anda ingin menyimpannya sebagai referensi
// class BottomRightRoundedClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     double curveHeight = 80.0;

//     path.lineTo(0, size.height - curveHeight);
//     path.quadraticBezierTo(0, size.height, curveHeight / 2, size.height);
//     path.lineTo(size.width - (curveHeight / 2), size.height);

//     path.quadraticBezierTo(
//         size.width, size.height,
//         size.width, size.height - curveHeight
//     );
//     path.lineTo(size.width, 0);
//     path.close();

//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }