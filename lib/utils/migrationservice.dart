import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../presentation/login/login_controller.dart';

class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method untuk menjalankan migrasi isLogin field ke semua user existing
  static Future<void> migrateIsLoginField() async {
    try {
      print('MigrationService: Starting isLogin field migration');

      // Ambil semua user dari collection
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        print('MigrationService: No users found, migration not needed');
        return;
      }

      WriteBatch batch = _firestore.batch();
      int updateCount = 0;

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        try {
          Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

          // Cek apakah field isLogin sudah ada
          if (!userData.containsKey('isLogin')) {
            batch.update(doc.reference, {
              'isLogin': false, // Default false untuk user existing
              'isLoginFieldAddedAt': FieldValue.serverTimestamp(),
              'migratedBy': 'MigrationService',
            });
            updateCount++;
            String email = userData['email'] ?? 'Unknown';
            print('MigrationService: Will add isLogin field to: $email');
          }
        } catch (e) {
          print('MigrationService: Error processing document ${doc.id}: $e');
          continue;
        }
      }

      // Commit batch jika ada update
      if (updateCount > 0) {
        await batch.commit();
        print('MigrationService: Successfully migrated $updateCount users');

        Get.snackbar(
          'Migrasi Berhasil',
          'Field isLogin berhasil ditambahkan ke $updateCount user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        print('MigrationService: All users already have isLogin field');
      }

    } catch (e, stackTrace) {
      print('MigrationService: Error during migration: $e');
      print('MigrationService: StackTrace: $stackTrace');

      Get.snackbar(
        'Migrasi Gagal',
        'Terjadi kesalahan saat migrasi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Method untuk cek status migrasi
  static Future<Map<String, dynamic>> checkMigrationStatus() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      int totalUsers = usersSnapshot.docs.length;
      int usersWithIsLogin = 0;
      int usersWithoutIsLogin = 0;
      List<String> usersNeedMigration = [];

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        if (userData.containsKey('isLogin')) {
          usersWithIsLogin++;
        } else {
          usersWithoutIsLogin++;
          String email = userData['email'] ?? userData['uid'] ?? 'Unknown';
          usersNeedMigration.add(email);
        }
      }

      bool migrationComplete = usersWithoutIsLogin == 0;

      print('MigrationService: Migration Status Check:');
      print('  Total Users: $totalUsers');
      print('  Users with isLogin: $usersWithIsLogin');
      print('  Users without isLogin: $usersWithoutIsLogin');
      print('  Migration Complete: $migrationComplete');

      return {
        'totalUsers': totalUsers,
        'usersWithIsLogin': usersWithIsLogin,
        'usersWithoutIsLogin': usersWithoutIsLogin,
        'usersNeedMigration': usersNeedMigration,
        'migrationComplete': migrationComplete,
      };

    } catch (e) {
      print('MigrationService: Error checking migration status: $e');
      return {
        'error': e.toString(),
        'migrationComplete': false,
      };
    }
  }

  // Method untuk menjalankan migrasi otomatis saat aplikasi pertama kali jalan
  static Future<void> runAutoMigrationOnce() async {
    try {
      // Cek apakah migrasi sudah pernah dijalankan
      DocumentSnapshot migrationDoc = await _firestore
          .collection('system')
          .doc('migration_status')
          .get();

      if (migrationDoc.exists) {
        Map<String, dynamic> migrationData = migrationDoc.data() as Map<String, dynamic>;
        bool isLoginMigrationDone = migrationData['isLoginFieldMigration'] ?? false;

        if (isLoginMigrationDone) {
          print('MigrationService: isLogin migration already completed previously');
          return;
        }
      }

      print('MigrationService: Running first-time migration for isLogin field');

      // Jalankan migrasi
      await migrateIsLoginField();

      // Tandai migrasi sebagai selesai
      await _firestore.collection('system').doc('migration_status').set({
        'isLoginFieldMigration': true,
        'isLoginMigrationCompletedAt': FieldValue.serverTimestamp(),
        'migrationVersion': '1.0.0',
      }, SetOptions(merge: true));

      print('MigrationService: Auto migration completed and marked as done');

    } catch (e) {
      print('MigrationService: Error in auto migration: $e');
    }
  }
}

// Extension untuk LoginController
extension LoginControllerMigration on LoginController {
  // Method yang bisa dipanggil dari LoginController untuk migrasi
  Future<void> runMigrationIfNeeded() async {
    await MigrationService.runAutoMigrationOnce();
  }

  // Method untuk cek status migrasi dari UI
  Future<void> checkAndShowMigrationStatus() async {
    Map<String, dynamic> status = await MigrationService.checkMigrationStatus();

    if (status['error'] != null) {
      Get.snackbar(
        'Error',
        'Gagal mengecek status migrasi: ${status['error']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    String message = '''
Total Users: ${status['totalUsers']}
Users dengan isLogin: ${status['usersWithIsLogin']}
Users tanpa isLogin: ${status['usersWithoutIsLogin']}
Migrasi Complete: ${status['migrationComplete'] ? 'Ya' : 'Tidak'}
    ''';

    Get.dialog(
      AlertDialog(
        title: Text('Status Migrasi isLogin'),
        content: Text(message),
        actions: [
          if (!status['migrationComplete'])
            TextButton(
              onPressed: () async {
                Get.back();
                await MigrationService.migrateIsLoginField();
              },
              child: Text('Jalankan Migrasi'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }
}