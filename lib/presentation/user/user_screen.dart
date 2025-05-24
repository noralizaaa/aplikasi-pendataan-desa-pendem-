// lib/presentation/user/user_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_controller.dart';

class UserScreen extends GetView<UserController> {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              controller.logout();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selamat Datang, User!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Obx(() => Text('Email: ${controller.userEmail ?? 'Tidak diketahui'}')),
            Obx(() => Text('Role: ${controller.userRole ?? 'Tidak diketahui'}')),
            // Tambahkan konten khusus user di sini
          ],
        ),
      ),
    );
  }
}
