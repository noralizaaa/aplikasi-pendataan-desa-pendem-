import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/prototype/prototype_screen.dart';
import '../../presentation/prototype/prototype_controller.dart';
import '../../presentation/screens.dart';
import 'bindings/splash_binding.dart';
import 'bindings/controllers/controllers_bindings.dart';

enum Environments { DEVELOPMENT, QAS, PRODUCTION }

class ConfigEnvironments {
  static Map<String, String> getEnvironments() {
    return {'env': Environments.DEVELOPMENT.name}; // Sesuaikan dengan config.dart
  }
}

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  const EnvironmentsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    return env != Environments.PRODUCTION.name
        ? Banner(
      location: BannerLocation.topStart,
      message: env!,
      color: env == Environments.QAS.name ? Colors.blue : Colors.purple,
      child: child,
    )
        : SizedBox(child: child);
  }
}

class AppRoutes {
  static const String splash = '/splash';
  static const String prototype = '/prototype';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: prototype,
      page: () => const PrototypeScreen(),
      binding: BindingsBuilder(() {
        print('PrototypeBinding: Initializing PrototypeController');
        Get.lazyPut(() => PrototypeController());
      }),
    ),
  ];
}