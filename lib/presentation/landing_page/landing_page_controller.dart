import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// [LandingPageController] mengelola logika tampilan dan animasi pada Landing Page.
/// 
/// Bertanggung jawab untuk mengatur kemunculan elemen visual secara bertahap
/// (sequencing) menggunakan variabel reaktif [GetX].
class LandingPageController extends GetxController {
  /// Menandakan visibilitas logo utama (BPS).
  final isLogoVisible = false.obs;
  /// Menandakan visibilitas ilustrasi utama halaman.
  final isIllustrationVisible = false.obs;

  // KONSTRUKTOR YANG BENAR: Nama harus sama dengan kelass
  LandingPageController() {
    debugPrint('LandingPageController: Constructor called');
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('LandingPageController: onInit called');
    _startAnimation();
  }

  /// Memulai rangkaian animasi kemunculan elemen UI.
  /// 
  /// Logo akan muncul segera, diikuti oleh ilustrasi dengan jeda waktu tertentu
  /// untuk memberikan efek visual yang halus.
  void _startAnimation() async {
    // Show logo immediately
    isLogoVisible.value = true;
    debugPrint('LandingPageController: Logo animation started');

    // Wait a bit, then show illustration
    // Anda bisa menyesuaikan durasi delay ini
    await Future.delayed(const Duration(milliseconds: 800)); // Contoh delay
    isIllustrationVisible.value = true;
    debugPrint('LandingPageController: Illustration animation started');
  }
}