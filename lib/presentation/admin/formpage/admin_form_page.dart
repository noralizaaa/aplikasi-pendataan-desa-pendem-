// Path: lib/presentation/admin/formpage/admin_form_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import Get if you plan to use GetX features here

class AdminFormPage extends StatelessWidget {
  const AdminFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Form Admin'),
        backgroundColor: const Color(0xFFFF9800), // Matching your accentHeaderColor
        foregroundColor: Colors.white, // For text and icons
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Konten Halaman Form Admin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Di sini Anda bisa menampilkan daftar form, membuat form baru, dll.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}