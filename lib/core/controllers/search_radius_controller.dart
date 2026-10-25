import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How far (in km) from the customer's current location salons are shown on
/// Home and Explore. Defaults to 2 km, persists across launches, and is
/// changed from the customer profile screen.
class SearchRadiusController extends GetxController {
  static const List<int> options = [2, 5, 10, 20, 25];
  static const int defaultKm = 2;
  static const String _prefKey = 'search_radius_km';

  final RxInt km = defaultKm.obs;

  /// Safe from anywhere — registers itself on first use, no main.dart change.
  static SearchRadiusController get instance =>
      Get.isRegistered<SearchRadiusController>()
          ? Get.find<SearchRadiusController>()
          : Get.put(SearchRadiusController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKey);
      if (saved != null && options.contains(saved)) km.value = saved;
    } catch (_) {}
  }

  Future<void> setRadius(int value) async {
    if (!options.contains(value)) return;
    km.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, value);
    } catch (_) {}
  }
}