import 'package:get/get.dart';

class PrototypeController extends GetxController {
  // Reactive variables to control visibility
  final isLogoVisible = false.obs;
  final isIllustrationVisible = false.obs;

  PrototypeController() {
    print('PrototypeController: Constructor called');
  }

  @override
  void onInit() {
    super.onInit();
    print('PrototypeController: onInit called');
    _startAnimation();
  }

  void _startAnimation() async {
    // Show logo immediately
    isLogoVisible.value = true;
    print('PrototypeController: Logo animation started');

    // Wait 1 second, then show illustration
    await Future.delayed(const Duration(milliseconds: 1000));
    isIllustrationVisible.value = true;
    print('PrototypeController: Illustration animation started');
  }
}