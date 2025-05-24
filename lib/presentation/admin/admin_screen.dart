// lib/presentation/admin/admin_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';

class AdminScreen extends GetView<AdminController> {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Admin'),
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
              'Selamat Datang, Admin!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Obx(() => Text('Email: ${controller.userEmail ?? 'Tidak diketahui'}')),
            Obx(() => Text('Role: ${controller.userRole ?? 'Tidak diketahui'}')),
            // Tambahkan konten khusus admin di sini
          ],
        ),
      ),
    );
  }
}
