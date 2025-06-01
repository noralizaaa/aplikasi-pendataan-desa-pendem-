import 'package:get/get.dart';

class LandingPageController extends GetxController {
  // Reactive variables to control visibility
  final isLogoVisible = false.obs;
  final isIllustrationVisible = false.obs;

  // KONSTRUKTOR YANG BENAR: Nama harus sama dengan kelas
  LandingPageController() {
    print('LandingPageController: Constructor called');
  }

  @override
  void onInit() {
    super.onInit();
    print('LandingPageController: onInit called');
    _startAnimation();
  }

  void _startAnimation() async {
    // Show logo immediately
    isLogoVisible.value = true;
    print('LandingPageController: Logo animation started');

    // Wait a bit, then show illustration
    // Anda bisa menyesuaikan durasi delay ini
    await Future.delayed(const Duration(milliseconds: 800)); // Contoh delay
    isIllustrationVisible.value = true;
    print('LandingPageController: Illustration animation started');
  }
}