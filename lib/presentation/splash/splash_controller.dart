import 'package:get/get.dart';
import '../../infrastructure/navigation/routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('SplashController: onInit called');
    _navigateToPrototype();
  }

  void _navigateToPrototype() async {
    try {
      print('SplashController: Waiting for 3 seconds');
      await Future.delayed(const Duration(seconds: 3));
      print('SplashController: Navigating to ${AppRoutes.landingPage}');
      Get.offNamed(AppRoutes.landingPage);
    } catch (e, stackTrace) {
      print('SplashController: Error navigating to PrototypeScreen: $e');
      print('StackTrace: $stackTrace');
    }
  }
}

