import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../infrastructure/navigation/routes.dart'; // Make sure this path is correct

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

      // Wait for 2 seconds for the splash screen
      await Future.delayed(const Duration(seconds: 4));

      // Check if there is a currently logged-in user in Firebase Auth
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        print('SplashController: Firebase user found: ${currentUser.email}');

        // Check isLogin status in Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Check if 'isLogin' field exists, if not, add it
          if (!userData.containsKey('isLogin')) {
            print('SplashController: isLogin field not found, adding it...');
            // Add 'isLogin' field with value true because user is still logged in via Firebase Auth
            await _firestore.collection('users').doc(currentUser.uid).update({
              'isLogin': true,
              'lastLoginAt': FieldValue.serverTimestamp(),
              'isLoginFieldAddedAt': FieldValue.serverTimestamp(), // For tracking when the field was added
            });
            userData['isLogin'] = true; // Update local copy
            print('SplashController: Added isLogin field with value: true');
          }

          bool isLogin = userData['isLogin'] ?? false;
          print('SplashController: isLogin status: $isLogin');

          if (isLogin) {
            // User is still in logged-in status, navigate based on role
            String role = userData['role'] ?? 'user'; // Default to 'user' if role is not set
            String? programId = userData['programId']; // programId can be null

            print('SplashController: User is logged in. Role: $role, ProgramId: $programId');

            if (role == 'admin' || programId == 'admin') { // Consider if 'admin' in programId is a valid check
              print('SplashController: Navigating to Admin Page');
              Get.offAllNamed(AppRoutes.adminPage);
            } else {
              print('SplashController: Navigating to User Page');
              Get.offAllNamed(AppRoutes.userPage);
            }
          } else {
            // User has logged out, sign out from Firebase Auth and navigate to landing page
            print('SplashController: User is logged out (isLogin is false), signing out from Firebase Auth');
            await _auth.signOut();
            Get.offAllNamed(AppRoutes.landingPage); // Changed from AppRoutes.login
          }
        } else {
          // User document does not exist, create a new one with isLogin true
          print('SplashController: User document not found, creating new one');
          await _firestore.collection('users').doc(currentUser.uid).set({
            'uid': currentUser.uid,
            'email': currentUser.email,
            'role': 'user', // Default role for new user
            'programId': '000', // Default programId for new user, adjust as needed
            'isLogin': true,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Navigate to user page for new user
          print('SplashController: New user created, navigating to User Page');
          Get.offAllNamed(AppRoutes.userPage);
        }
      } else {
        // No user logged in via Firebase Auth
        print('SplashController: No Firebase user found, navigating to Landing Page');
        Get.offAllNamed(AppRoutes.landingPage); // Changed from AppRoutes.login
      }

    } catch (e, stackTrace) {
      print('SplashController: Error checking login status: $e');
      print('StackTrace: $stackTrace');

      // If an error occurs, navigate to landing page as a fallback
      Get.offAllNamed(AppRoutes.landingPage); // Changed from AppRoutes.login
    }
  }

  // Method to update all existing users with the 'isLogin' field
  // This is a utility method and might not be called during normal splash screen flow
  // unless explicitly triggered.
  Future<void> updateAllUsersWithIsLoginField() async {
    try {
      print('SplashController: Starting batch update for all users to add isLogin field if missing');

      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      WriteBatch batch = _firestore.batch();
      int usersUpdatedCount = 0;

      for (QueryDocumentSnapshot doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Check if 'isLogin' field already exists
        if (!userData.containsKey('isLogin')) {
          // Add 'isLogin' field with a default value (e.g., false)
          // The actual login status will be determined by _checkLoginStatus for active sessions
          batch.update(doc.reference, {
            'isLogin': false, // Default to false, active sessions will update it
            'updatedAt': FieldValue.serverTimestamp(), // Track update time
            'isLoginFieldAddedAt': FieldValue.serverTimestamp(), // Specifically track this addition
          });
          usersUpdatedCount++;
          print('SplashController: Adding isLogin field to user: ${userData['email']} (UID: ${doc.id})');
        }
      }

      if (usersUpdatedCount > 0) {
        // Commit batch update only if there are changes
        await batch.commit();
        print('SplashController: Batch update completed successfully. $usersUpdatedCount users updated.');
      } else {
        print('SplashController: No users needed updating for the isLogin field.');
      }

    } catch (e) {
      print('SplashController: Error in batch update: $e');
    }
  }
}