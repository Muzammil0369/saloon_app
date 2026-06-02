import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saloon_app/core/services/database_service.dart';

class UserController extends GetxController {
  final RxString userName = 'Loading...'.obs;
  final RxString userEmail = 'Loading...'.obs;
  
  final DatabaseService _dbService = Get.find<DatabaseService>();

  @override
  void onInit() {
    super.onInit();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? 'No email';
      
      final doc = await _dbService.getUserProfile(user.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        userName.value = data['name'] ?? 'User';
      } else {
        userName.value = 'User';
      }
    }
  }

  void refreshProfile() => _fetchProfile();
}
