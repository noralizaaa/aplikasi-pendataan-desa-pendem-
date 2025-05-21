import 'package:get/get.dart';
import '../../../presentation/splash/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    print('SplashBinding: Initializing SplashController');
    Get.lazyPut<SplashController>(() => SplashController(), fenix: true);
  }
}