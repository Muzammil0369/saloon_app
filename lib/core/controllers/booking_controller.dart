import 'package:get/get.dart';

class BookingController extends GetxController {
  // Store services as a list of maps, with an observable 'isSelected' status
  var services = <Map<String, dynamic>>[
    {'name': 'Classic Haircut', 'price': 500, 'duration': 30, 'isSelected': false},
    {'name': 'Beard Trim & Shape', 'price': 300, 'duration': 20, 'isSelected': false},
    {'name': 'Facial Spa', 'price': 1200, 'duration': 45, 'isSelected': false},
    {'name': 'Hair Color (Global)', 'price': 2500, 'duration': 90, 'isSelected': false},
    {'name': 'Head Massage', 'price': 400, 'duration': 15, 'isSelected': false},
  ].obs;

  double get totalPrice => services
      .where((s) => s['isSelected'] == true)
      .fold(0, (sum, item) => sum + (item['price'] as int));

  int get totalDuration => services
      .where((s) => s['isSelected'] == true)
      .fold(0, (sum, item) => sum + (item['duration'] as int));

  List<Map<String, dynamic>> get selectedServices => 
      services.where((s) => s['isSelected'] == true).toList();

  void toggleService(int index) {
    services[index]['isSelected'] = !services[index]['isSelected'];
    services.refresh();
  }
}
