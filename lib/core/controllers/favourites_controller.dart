import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FavouritesController extends GetxController {
  final RxSet<String> favouriteIds = <String>{}.obs;
  final RxBool isLoading = true.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadFavourites();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _loadFavourites();
    });
  }

  Future<void> _loadFavourites() async {
    isLoading.value = true;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      favouriteIds.clear();
      isLoading.value = false;
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final List<dynamic> ids = data?['favouriteSalons'] ?? [];
      favouriteIds.value = ids.map((e) => e.toString()).toSet();
    } catch (e) {
      favouriteIds.clear();
    }
    isLoading.value = false;
  }

  bool isFavourite(String ownerId) => favouriteIds.contains(ownerId);

  Future<void> toggleFavourite(String ownerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || ownerId.isEmpty) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    if (favouriteIds.contains(ownerId)) {
      favouriteIds.remove(ownerId);
      favouriteIds.refresh();
      await userRef.update({
        'favouriteSalons': FieldValue.arrayRemove([ownerId]),
      });
    } else {
      favouriteIds.add(ownerId);
      favouriteIds.refresh();
      await userRef.update({
        'favouriteSalons': FieldValue.arrayUnion([ownerId]),
      });
    }
  }

  // Public so the favourites screen can refresh after navigating away/back
  Future<void> refresh() => _loadFavourites();
}