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
    print('SplashScreen: Building UI with White Background & Glassmorphism Effect');

    Get.find<SplashController>();
    precacheImage(const AssetImage('assets/images/bps.png'), context);

    return Scaffold(
      // Tidak perlu backgroundColor di Scaffold jika Stack mengisi seluruh layar
      body: Stack( // Kita butuh Stack untuk menumpuk lapisan glassmorphism
        children: [
          // 1. Lapisan Paling Bawah: PUTIH BERSIH
          Container(
            color: Colors.white, // Background putih solid
          ),

          // Lapisan Tambahan (Opsional): Sedikit noise/tekstur halus di atas putih
          // Bisa memberikan kedalaman ekstra pada efek glassmorphism
          // Jika tidak ingin, hapus saja Container ini.
          // Container(
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('assets/images/subtle_noise.png'), // GANTI DENGAN ASET NOISE ANDA
          //       fit: BoxFit.cover,
          //       opacity: 0.03, // Opacity sangat rendah untuk noise
          //     ),
          //   ),
          // ),


          // 2. Lapisan Efek Kaca Buram (Glassmorphism)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Sesuaikan nilai blur
              child: Container(
                decoration: BoxDecoration(
                  // Warna semi-transparan untuk efek "kaca".
                  color: glassLayerColor,
                  // Opsional: Border tipis untuk mempertegas efek kaca
                  border: Border.all(
                    color: glassBorderColor,
                    width: 0.8,
                  ),
                  // Jika ingin sudut kaca melengkung (misalnya jika tidak full screen)
                  // borderRadius: BorderRadius.circular(20),
                ),
                // Child container ini harus ada, meskipun kosong, agar BackdropFilter bekerja
                // pada elemen di BAWAHNYA dalam Stack (yaitu Container putih).
              ),
            ),
          ),

          // 3. Konten Utama (Logo) di atas lapisan glassmorphism
          Center(
            child: FadeInAnimation( // Asumsi FadeInAnimation masih ada
              child: Image.asset(
                'assets/images/bps.png', // Pastikan path aset ini benar
                width: 200,
                height: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Implementasi FadeInAnimation (pasti sudah ada jika kode sebelumnya berjalan)
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
      duration: const Duration(milliseconds: 1200),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    print('FadeInAnimation: Animation started');
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