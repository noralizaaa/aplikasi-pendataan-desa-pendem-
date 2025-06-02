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
    // Anda mungkin ingin melakukan precache gambar daun juga jika ukurannya besar
    // precacheImage(const AssetImage('assets/images/leaf_top_left.png'), context);
    // precacheImage(const AssetImage('assets/images/leaf_bottom_right.png'), context);


    // Get media size for responsive image sizing if needed
    // final mediaSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Lapisan Paling Bawah: PUTIH BERSIH
          Container(
            color: Colors.white, // Background putih solid
          ),

          // (Optional) Noise layer - kept commented as per original
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
                  color: glassLayerColor,
                  border: Border.all(
                    color: glassBorderColor,
                    width: 0.8,
                  ),
                  // Anda bisa menambahkan borderRadius di sini jika ingin sudut kaca yang melengkung
                  // borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          // BARU: Dekorasi Daun Hijau ================================================
          // Daun di Pojok Kiri Atas
          Positioned(
            top: 40, // Sesuaikan posisi dari atas
            left: 30,  // Sesuaikan posisi dari kiri
            child: FadeInAnimation(
              child: Image.asset(
                'assets/images/leaf_top_left.png', // <<< GANTI DENGAN ASET DAUN ANDA
                width: 100, // Sesuaikan ukuran
                height: 100, // Sesuaikan ukuran
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading leaf_top_left.png: $error");
                  // Tidak menampilkan apa-apa jika gambar gagal dimuat
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // Daun di Pojok Kanan Bawah
          Positioned(
            bottom: 80, // Sesuaikan posisi dari bawah (di atas logo bawah)
            right: 30,   // Sesuaikan posisi dari kanan
            child: FadeInAnimation(
              child: Image.asset(
                'assets/images/leaf_bottom_right.png', // <<< GANTI DENGAN ASET DAUN ANDA
                width: 90, // Sesuaikan ukuran
                height: 90, // Sesuaikan ukuran
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading leaf_bottom_right.png: $error");
                  // Tidak menampilkan apa-apa jika gambar gagal dimuat
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // AKHIR BARU: Dekorasi Daun Hijau ===========================================

          // 3. Konten Utama (Logo Tengah) di atas lapisan glassmorphism
          Center(
            child: FadeInAnimation(
              child: Image.asset(
                  'assets/images/splashpage_1.png', // <<< CHANGED LOGO
                  width: 200, // You can adjust this
                  height: 200, // You can adjust this
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
              padding: const EdgeInsets.only(bottom: 15.0), // Jarak 15px dari bawah
              child: FadeInAnimation( // Apply fade-in animation
                child: Image.asset(
                    'assets/images/splashpage.png', // <<< NEW BOTTOM LOGO
                    width: 180, // Adjust width as needed, e.g., mediaSize.width * 0.4
                    // height: 60, // Optionally specify height or let fit: BoxFit.contain manage it
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading splashpage.png: $error"); // Path yang benar adalah splashpage.png
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
    // Optional: Add a slight delay for the second image if needed,
    // but for now, both start animating when widget is built.
    // For simultaneous animation, this is fine.
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
