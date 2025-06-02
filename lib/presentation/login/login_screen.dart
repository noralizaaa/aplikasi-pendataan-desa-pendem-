import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../infrastructure/navigation/routes.dart';
import 'login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  // Definisi Warna (agar mudah diubah)
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryTextColor = Colors.white;
  static const Color textFieldDefaultColor = Colors.black54;
  static const Color textFieldFocusedColor = Colors.black;
  static const Color textFieldFillColor = Colors.white;
  static const Color buttonLoginColor = Color(0xFFF57C00);

  @override
  Widget build(BuildContext context) {
    print('DEBUG: LoginScreen loaded. Current route: ${Get.currentRoute}, Previous route: ${Get.previousRoute}');
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () {
            print('DEBUG: Back button pressed. Navigating to LandingPage.');
            Get.offNamed(AppRoutes.landingPage);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 40),
              Text(
                'Silakan isi Username dan\nPassword Terlebih Dahulu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 50),
              _buildUsernameField(context),
              const SizedBox(height: 25),
              _buildPasswordField(context),
              const SizedBox(height: 60),
              _buildLoginButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    return TextField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Username',
        hintStyle: TextStyle(color: textFieldDefaultColor.withOpacity(0.7)),
        labelText: 'Username',
        labelStyle: const TextStyle(color: textFieldDefaultColor),
        filled: true,
        fillColor: textFieldFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: textFieldDefaultColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: textFieldDefaultColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: textFieldFocusedColor, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Obx(
          () => TextField(
        controller: controller.passwordController,
        obscureText: !controller.isPasswordVisible.value,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: textFieldDefaultColor.withOpacity(0.7)),
          labelText: 'Password',
          labelStyle: const TextStyle(color: textFieldDefaultColor),
          filled: true,
          fillColor: textFieldFillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: textFieldDefaultColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: textFieldDefaultColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: textFieldFocusedColor, width: 2.0),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: textFieldDefaultColor,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Obx(
          () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.loginUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonLoginColor,
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
          ),
          child: controller.isLoading.value
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LOG IN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}