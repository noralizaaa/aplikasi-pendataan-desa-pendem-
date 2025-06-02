import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../infrastructure/navigation/routes.dart';

class SplashController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    print('SplashController: onInit called');
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    try {
      print('SplashController: Checking login status');

      // Tunggu 2 detik untuk splash screen
      await Future.delayed(const Duration(seconds: 2));

      // Cek apakah ada user yang sedang login di Firebase Auth
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        print('SplashController: Firebase user found: ${currentUser.email}');

        // Cek status isLogin di Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Cek apakah field isLogin ada, jika tidak ada tambahkan
          if (!userData.containsKey('isLogin')) {
            print('SplashController: isLogin field not found, adding it...');
            // Tambahkan field isLogin dengan nilai true karena user masih login di Firebase Auth
            await _firestore.collection('users').doc(currentUser.uid).update({
              'isLogin': true,
              'lastLoginAt': FieldValue.serverTimestamp(),
              'isLoginFieldAddedAt': FieldValue.serverTimestamp(),
            });
            userData['isLogin'] = true;
            print('SplashController: Added isLogin field with value: true');
          }

          bool isLogin = userData['isLogin'] ?? false;
          print('SplashController: isLogin status: $isLogin');

          if (isLogin) {
            // User masih dalam status login, navigasi berdasarkan role
            String role = userData['role'] ?? 'user';
            String? programId = userData['programId'];

            print('SplashController: User is logged in. Role: $role, ProgramId: $programId');

            if (role == 'admin' || programId == 'admin') {
              print('SplashController: Navigating to Admin Page');
              Get.offAllNamed(AppRoutes.adminPage);
            } else {
              print('SplashController: Navigating to User Page');
              Get.offAllNamed(AppRoutes.userPage);
            }
          } else {
            // User sudah logout, sign out dari Firebase Auth dan ke login
            print('SplashController: User is logged out, signing out from Firebase Auth');
            await _auth.signOut();
            Get.offAllNamed(AppRoutes.login);
          }
        } else {
          // User document tidak ada, buat baru dengan isLogin true
          print('SplashController: User document not found, creating new one');
          await _firestore.collection('users').doc(currentUser.uid).set({
            'uid': currentUser.uid,
            'email': currentUser.email,
            'role': 'user',
            'programId': '000',
            'isLogin': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Navigasi ke user page untuk user baru
          print('SplashController: New user created, navigating to User Page');
          Get.offAllNamed(AppRoutes.userPage);
        }
      } else {
        // Tidak ada user yang login di Firebase Auth
        print('SplashController: No Firebase user found, navigating to login');
        Get.offAllNamed(AppRoutes.login);
      }

    } catch (e, stackTrace) {
      print('SplashController: Error checking login status: $e');
      print('StackTrace: $stackTrace');

      // Jika ada error, navigasi ke login page sebagai fallback
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // Method untuk mengupdate semua user yang sudah ada dengan field isLogin
  Future<void> updateAllUsersWithIsLoginField() async {
    try {
      print('SplashController: Starting batch update for all users');

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Cek apakah field isLogin sudah ada
        if (!userData.containsKey('isLogin')) {
          // Tambahkan field isLogin dengan nilai false sebagai default
          batch.update(doc.reference, {
            'isLogin': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('SplashController: Adding isLogin field to user: ${userData['email']}');
        }
      }

      // Commit batch update
      await batch.commit();
      print('SplashController: Batch update completed successfully');

    } catch (e) {
      print('SplashController: Error in batch update: $e');
    }
  }
}