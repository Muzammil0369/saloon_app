import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class BookingController extends GetxController {
  var services = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  // Make discountRate observable and use it to trigger updates in totalPrice
  var discountRate = 0.0.obs;

  // Load services - tries separate collection first, falls back to owner's embedded services
  Future<void> loadServices(String ownerId) async {
    isLoading.value = true;
    try {
      // First try to load from separate 'services' collection
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('ownerId', isEqualTo: ownerId)
          .where('isActive', isEqualTo: true)
          .get();

      if (servicesSnapshot.docs.isNotEmpty) {
        // Services exist in separate collection
        services.value = servicesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['serviceName'] ?? data['name'] ?? 'Unnamed Service',
            'price': _parsePrice(data['price']),
            'duration': _parseDuration(data['duration']),
            'description': data['description'] ?? '',
            'category': data['category'] ?? 'General',
            'isSelected': false,
          };
        }).toList();

        isLoading.value = false;
        return;
      }

      // Fallback: Load from owner's embedded services array
      final ownerDoc = await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .get();

      if (ownerDoc.exists) {
        final data = ownerDoc.data() as Map<String, dynamic>;
        final List<dynamic> fetchedServices = data['services'] ?? [];

        print('Loading embedded services for owner $ownerId: ${fetchedServices.length} services found');

        services.value = fetchedServices.map((s) {
          if (s is Map<String, dynamic>) {
            return {
              'id': s['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'name': s['name'] ?? s['serviceName'] ?? 'Unnamed Service',
              'price': _parsePrice(s['price']),
              'duration': _parseDuration(s['duration']),
              'description': s['description'] ?? '',
              'category': s['category'] ?? 'General',
              'isSelected': false,
            };
          }
          return {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': 'Unknown Service',
            'price': 0,
            'duration': 30,
            'description': '',
            'category': 'General',
            'isSelected': false,
          };
        }).toList();
      } else {
        services.value = [];
      }
    } catch (e) {
      print('Error loading services: $e');
      services.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // Parse price to int - handles both String and int types
  int _parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is int) return price;
    if (price is double) return price.toInt();
    if (price is String) {
      // Remove any non-numeric characters except decimal point
      final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
      return int.tryParse(cleaned.split('.').first) ?? 0;
    }
    return 0;
  }

  // Parse duration to int - handles both String and int types
  int _parseDuration(dynamic duration) {
    if (duration == null) return 30;
    if (duration is int) return duration;
    if (duration is double) return duration.toInt();
    if (duration is String) {
      return int.tryParse(duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 30;
    }
    return 30;
  }

  double get totalPrice {
    double subtotal = 0;
    for (var service in services) {
      if (service['isSelected'] == true) {
        final price = service['price'];
        if (price is int) {
          subtotal += price.toDouble();
        } else if (price is double) {
          subtotal += price;
        } else if (price is String) {
          subtotal += double.tryParse(price) ?? 0;
        }
      }
    }
    
    // Use .value to get the value from RxDouble
    final discount = discountRate.value;
    print('DEBUG: totalPrice getter called. Subtotal: $subtotal, Discount: $discount%');
    
    if (discount > 0) {
      final total = subtotal * (1 - (discount / 100));
      print('DEBUG: Final total: $total');
      return total;
    }
    print('DEBUG: Final total: $subtotal');
    return subtotal;
  }

  int get totalDuration {
    int total = 0;
    for (var service in services) {
      if (service['isSelected'] == true) {
        total += service['duration'] as int;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> get selectedServices =>
      services.where((s) => s['isSelected'] == true).toList();

  void toggleService(int index) {
    if (index < services.length) {
      services[index]['isSelected'] = !(services[index]['isSelected'] ?? false);
      services.refresh();
    }
  }

  void clearSelection() {
    for (var service in services) {
      service['isSelected'] = false;
    }
    services.refresh();
  }

  @override
  void onClose() {
    super.onClose();
  }
}