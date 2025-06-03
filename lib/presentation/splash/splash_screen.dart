import 'dart:ui'; // Untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart'; // Pastikan path ini benar

// Warna untuk lapisan kaca - putih dengan opacity
// Sesuaikan opacity ini untuk kekuatan efek kaca
final Color glassLayerColor = Colors.white.withOpacity(0.35); // Contoh: 35% opacity
// Warna untuk border tipis pada kaca (opsional, tapi bisa mempercantik)
final Color glassBorderColor = Colors.white.withOpacity(0.5);

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('SplashScreen: Building UI with White Background, Glassmorphism Effect, and Leaf Decorations');
    // Initialize controller if not already done by GetX binding
    Get.find<SplashController>();

    // Precache images
    precacheImage(const AssetImage('assets/images/splashpage.png'), context);
    precacheImage(const AssetImage('assets/images/splashpage_1.png'), context);
    precacheImage(const AssetImage('assets/images/DaunSS.png'), context); // Precache gambar daun baru


    // Get media size for responsive image sizing if needed
    // final mediaSize = MediaQuery.of(context).size;
    const double leafSize = 500.0; // Ukuran default untuk daun, bisa disesuaikan
    const double leafCornerOffset = -50.0; // Padding dari tepi layar, set 0 jika ingin menempel

    return Scaffold(
      body: Stack(
        children: [
          // 1. Lapisan Paling Bawah: PUTIH BERSIH
          Container(
            color: Colors.white, // Background putih solid
          ),

          // (Optional) Noise layer - kept commented as per original
          // ...

          // 2. Lapisan Efek Kaca Buram (Glassmorphism)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Sesuaikan nilai blur
              child: Container(
                decoration: BoxDecoration(
                  color: glassLayerColor,
                  border: Border.all(
                    color: glassBorderColor,
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),

          // --- MODIFIKASI: Dekorasi DaunSS.png di 4 Sudut ---
          // Daun di Pojok Kiri Atas
          Positioned(
            top: leafCornerOffset,  // Menggunakan offset
            left: leafCornerOffset, // Menggunakan offset
            child: FadeInAnimation(
              child: Image.asset(
                'assets/images/DaunSS.png',
                width: leafSize,
                height: leafSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading DaunSS.png (top-left): $error");
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Daun di Pojok Kanan Atas
          Positioned(
            top: leafCornerOffset,   // Menggunakan offset
            right: leafCornerOffset, // Menggunakan offset
            child: FadeInAnimation(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159), // Flip horizontal
                transformHitTests: false, // Tidak menangkap event sentuh
                child: Image.asset(
                  'assets/images/DaunSS.png',
                  width: leafSize,
                  height: leafSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading DaunSS.png (top-right): $error");
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // Daun di Pojok Kiri Bawah
          Positioned(
            bottom: leafCornerOffset, // Menggunakan offset
            left: leafCornerOffset,  // Menggunakan offset
            child: FadeInAnimation(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationX(3.14159), // Flip vertikal
                transformHitTests: false, // Tidak menangkap event sentuh
                child: Image.asset(
                  'assets/images/DaunSS.png',
                  width: leafSize,
                  height: leafSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading DaunSS.png (bottom-left): $error");
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // Daun di Pojok Kanan Bawah
          Positioned(
            bottom: leafCornerOffset, // Menggunakan offset
            right: leafCornerOffset,  // Menggunakan offset
            child: FadeInAnimation(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationZ(3.14159), // Putar 180 derajat
                transformHitTests: false, // Tidak menangkap event sentuh
                child: Image.asset(
                  'assets/images/DaunSS.png',
                  width: leafSize,
                  height: leafSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading DaunSS.png (bottom-right): $error");
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          // --- AKHIR MODIFIKASI ---


          // HAPUS ATAU KOMENTARI DEKORASI DAUN LAMA JIKA TIDAK DIPERLUKAN LAGI
          // // Daun di Pojok Kiri Atas (LAMA)
          // Positioned(
          //   top: 40,
          //   left: 30,
          //   child: FadeInAnimation(
          //     child: Image.asset(
          //       'assets/images/leaf_top_left.png', // INI ADALAH GAMBAR LAMA
          //       width: 100,
          //       height: 100,
          //       fit: BoxFit.contain,
          //       // ... errorBuilder ...
          //     ),
          //   ),
          // ),
          // // Daun di Pojok Kanan Bawah (LAMA)
          // Positioned(
          //   bottom: 80,
          //   right: 30,
          //   child: FadeInAnimation(
          //     child: Image.asset(
          //       'assets/images/leaf_bottom_right.png', // INI ADALAH GAMBAR LAMA
          //       width: 90,
          //       height: 90,
          //       fit: BoxFit.contain,
          //       // ... errorBuilder ...
          //     ),
          //   ),
          // ),


          // 3. Konten Utama (Logo Tengah) di atas lapisan glassmorphism
          Center(
            child: FadeInAnimation(
              child: Image.asset(
                  'assets/images/splashpage_1.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading splashpage_1.png: $error");
                    return const Icon(Icons.broken_image, size: 100, color: Colors.black54);
                  }
              ),
            ),
          ),

          // 4. Logo Bawah Tengah (splashpage.png)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: FadeInAnimation(
                child: Image.asset(
                    'assets/images/splashpage.png',
                    width: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading splashpage.png: $error");
                      return const Icon(Icons.broken_image, size: 50, color: Colors.black54);
                    }
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Implementasi FadeInAnimation (asumsi sudah ada dan benar)
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  const FadeInAnimation({super.key, required this.child});

  @override
  _FadeInAnimationState createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Duration of fade
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    print('FadeInAnimation: Animation started for a child widget');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: widget.child,
    );
  }
}