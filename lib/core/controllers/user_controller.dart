import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saloon_app/core/services/database_service.dart';
import 'package:saloon_app/core/controllers/language_controller.dart';

class UserController extends GetxController {
  final RxString userName = 'User'.obs;
  final RxString userNameUr = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userRole = ''.obs;
  final RxString userProfileImage = ''.obs;
  final RxBool isLoading = true.obs;

  final DatabaseService _dbService = Get.find<DatabaseService>();

  @override
  void onInit() {
    super.onInit();
    _fetchProfile();

    // ✅ Listen to auth state changes properly
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    isLoading.value = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userEmail.value = user.email ?? 'No email';

      try {
        final doc = await _dbService.getUserProfile(user.uid);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          userName.value = data['name'] ?? 'User';
          userNameUr.value = data['name_ur'] ?? data['name'] ?? 'User';
          userRole.value = data['role'] ?? '';
          userProfileImage.value = data['profileImage'] ?? '';
        } else {
          userName.value = 'User';
          userNameUr.value = 'User';
        }
      } catch (e) {
        print('Error fetching profile: $e');
        userName.value = 'User';
        userNameUr.value = 'User';
      }
    } else {
      userName.value = 'Guest';
      userNameUr.value = 'Guest';
    }
    isLoading.value = false;
  }

  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  void setUserData(Map<String, dynamic> data) {
    userName.value = data['name'] ?? 'User';
    userNameUr.value = data['name_ur'] ?? data['name'] ?? 'User';
    userEmail.value = data['email'] ?? '';
    userRole.value = data['role'] ?? '';
    userProfileImage.value = data['profileImage'] ?? '';
  }

  void clearUser() {
    userName.value = 'User';
    userNameUr.value = '';
    userEmail.value = '';
    userRole.value = '';
    userProfileImage.value = '';
  }

  // Helper getter for display name
  String get displayName {
    final langCode = Get.find<LanguageController>().languageCode;
    if (langCode == 'ur' && userNameUr.value.isNotEmpty) {
      return userNameUr.value;
    }
    return userName.value;
  }
}