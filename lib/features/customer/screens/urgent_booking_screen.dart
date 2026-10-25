import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:saloon_app/core/controllers/language_controller.dart';
import 'package:saloon_app/core/controllers/search_radius_controller.dart';
import 'package:saloon_app/core/controllers/user_controller.dart';
import 'package:saloon_app/core/services/auth_service.dart';
import 'package:saloon_app/core/services/booking_lock_service.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/customer/screens/success_screen.dart';

const String _notifyNewBookingUrl =
    'https://rzypfwjhngpwlxfbxtcg.supabase.co/functions/v1/notify-new-booking';
const String _supabasePublishableKey =
    'sb_publishable_iO6I9436lSKFoeq_9bDXgQ_p8hXXD2L';

const Color _urgentColor = Color(0xFFFF6B35);

/// "Need it now" flow:
///   1) pick a service  2) see salons with a free slot soon (nearest first)
///   3) confirm in a bottom sheet -> booking is created flagged `isUrgent`.
class UrgentBookingScreen extends StatefulWidget {
  const UrgentBookingScreen({super.key});

  @override
  State<UrgentBookingScreen> createState() => _UrgentBookingScreenState();
}

class _UrgentBookingScreenState extends State<UrgentBookingScreen> {
  static const List<String> _quickServices = [
    'Haircut',
    'Beard',
    'Shave',
    'Facial',
    'Hair Color',
    'Massage',
    'Manicure',
    'Threading',
  ];

  static const Map<String, IconData> _serviceIcons = {
    'Haircut': Icons.content_cut_rounded,
    'Beard': Icons.face_rounded,
    'Shave': Icons.auto_awesome_rounded,
    'Facial': Icons.spa_rounded,
    'Hair Color': Icons.palette_rounded,
    'Massage': Icons.self_improvement_rounded,
    'Manicure': Icons.back_hand_rounded,
    'Threading': Icons.linear_scale_rounded,
  };

  final TextEditingController _serviceController = TextEditingController();

  final List<String> _selected = [];
  int _windowMinutes = 120;
  bool _searching = false;
  bool _searched = false;
  bool _showResults = false; // false = pick services, true = results view
  String _progress = '';
  List<_UrgentOption> _results = [];

  // ───────────────────────── helpers ─────────────────────────

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  num _toNum(dynamic v, {num fallback = 0}) {
    if (v is num) return v;
    if (v is String) {
      return num.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback;
    }
    return fallback;
  }

  ImageProvider? _imageProvider(dynamic raw) {
    final url = raw?.toString() ?? '';
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatSlot(int minutes) {
    final m = minutes % (24 * 60);
    final hour24 = m ~/ 60;
    final minute = m % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _inText(int minutesFromNow) {
    if (minutesFromNow <= 5) return 'urgent_now'.tr;
    if (minutesFromNow < 60) return '${'urgent_in'.tr} $minutesFromNow ${'min'.tr}';
    final h = minutesFromNow ~/ 60;
    final m = minutesFromNow % 60;
    return '${'urgent_in'.tr} ${h}h${m > 0 ? ' ${m}m' : ''}';
  }

  Future<Position?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  // ───────────────────────── search logic ─────────────────────────

  void _toggleService(String name) {
    final key = name.toLowerCase();
    setState(() {
      if (_selected.any((s) => s.toLowerCase() == key)) {
        _selected.removeWhere((s) => s.toLowerCase() == key);
      } else {
        _selected.add(name);
      }
    });
  }

  void _addTypedService() {
    final text = _serviceController.text.trim();
    if (text.isEmpty) return;
    if (!_selected.any((s) => s.toLowerCase() == text.toLowerCase())) {
      setState(() => _selected.add(text));
    }
    _serviceController.clear();
  }

  int _parseSlotMinutes(String label) {
    // "03:30 PM" -> minutes since midnight
    try {
      final parts = label.split(' ');
      final hm = parts[0].split(':');
      var h = int.parse(hm[0]) % 12;
      final m = int.parse(hm[1]);
      if (parts[1].toUpperCase() == 'PM') h += 12;
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  int _slotsFor(int minutes) => ((minutes <= 0 ? 30 : minutes) / 30).ceil();

  Future<void> _findSalons() async {
    if (_serviceController.text.trim().isNotEmpty) _addTypedService();
    if (_selected.isEmpty) {
      Get.snackbar('required'.tr, 'urgent_pick_service'.tr);
      return;
    }
    FocusScope.of(context).unfocus();

    final terms = List<String>.from(_selected);

    setState(() {
      _showResults = true;
      _searching = true;
      _searched = false;
      _results = [];
      _progress = 'urgent_finding_salons'.tr;
    });

    try {
      final pos = await _getPosition();
      final snap = await FirebaseFirestore.instance.collection('owners').get();
      final isUr = Get.find<LanguageController>().languageCode.value == 'ur';

      // 1) salons that offer EVERY selected service, with distance
      final candidates = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final salonServices = ((data['services'] as List?) ?? [])
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList();

        final chosen = <Map<String, dynamic>>[];
        bool offersAll = true;
        for (final term in terms) {
          final matches = salonServices
              .where((s) => (s['name'] ?? s['serviceName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(term.toLowerCase()))
              .toList();
          if (matches.isEmpty) {
            offersAll = false;
            break;
          }
          // cheapest match for this term, avoiding duplicates
          matches.sort((a, b) =>
              _toNum(a['price']).compareTo(_toNum(b['price'])));
          final pick = matches.firstWhere(
                (m) => !chosen.any((c) =>
            c['name'] == (m['name'] ?? m['serviceName'] ?? 'Service')),
            orElse: () => matches.first,
          );
          final name = pick['name'] ?? pick['serviceName'] ?? 'Service';
          if (!chosen.any((c) => c['name'] == name)) {
            chosen.add({
              'id': pick['id']?.toString() ?? '$name',
              'name': name,
              'price': _toNum(pick['price']).toInt(),
              'duration': _toNum(pick['duration'], fallback: 30).toInt(),
              'description': pick['description'] ?? '',
              'category': pick['category'] ?? 'General',
              'isSelected': true,
            });
          }
        }
        if (!offersAll || chosen.isEmpty) continue;

        double? km;
        final loc = data['location'];
        if (pos != null && loc is GeoPoint) {
          km = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, loc.latitude, loc.longitude) /
              1000;
        }

        // only salons inside the customer's search radius
        if (km != null && km > SearchRadiusController.instance.km.value) {
          continue;
        }

        candidates.add({
          'ownerId': doc.id,
          'data': data,
          'chosenServices': chosen,
          'km': km,
          'name': isUr
              ? (data['salonName_ur'] ?? data['salonName'] ?? 'Unnamed Salon')
              : (data['salonName'] ?? 'Unnamed Salon'),
        });
      }

      candidates.sort((a, b) {
        final ka = a['km'] as double?;
        final kb = b['km'] as double?;
        if (ka == null && kb == null) return 0;
        if (ka == null) return 1;
        if (kb == null) return -1;
        return ka.compareTo(kb);
      });

      final nearest = candidates.take(15).toList();
      if (mounted) {
        setState(() => _progress =
        '${'urgent_checking'.tr} ${nearest.length} ${'salons_lowercase'.tr}…');
      }

      final checked = await Future.wait(nearest.map(_checkAvailability));
      final options = checked.whereType<_UrgentOption>().toList();

      options.sort((a, b) {
        final c = a.minutesFromNow.compareTo(b.minutesFromNow);
        if (c != 0) return c;
        return (a.km ?? 9999).compareTo(b.km ?? 9999);
      });

      if (!mounted) return;
      setState(() {
        _results = options;
        _searching = false;
        _searched = true;
      });
    } catch (e) {
      debugPrint('Urgent search error: $e');
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searched = true;
      });
      Get.snackbar('error'.tr, 'urgent_search_failed'.tr);
    }
  }

  /// Earliest start slot today (inside the chosen window) where one staff
  /// member is free for the WHOLE duration of all selected services.
  Future<_UrgentOption?> _checkAvailability(Map<String, dynamic> c) async {
    try {
      final data = c['data'] as Map<String, dynamic>;
      final ownerId = c['ownerId'] as String;
      final chosen = (c['chosenServices'] as List).cast<Map<String, dynamic>>();
      final now = DateTime.now();

      final hours = data['businessHours'] as Map<String, dynamic>?;
      final workingDays = Set<int>.from(
          (hours?['workingDays'] as List?)?.map((e) => e as int) ??
              [1, 2, 3, 4, 5, 6, 7]);
      if (!workingDays.contains(now.weekday)) return null;

      final openParts = ((hours?['openTime'] as String?) ?? '10:00').split(':');
      final closeParts =
      ((hours?['closeTime'] as String?) ?? '20:00').split(':');
      final start = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      var end = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      if (end <= start) end += 24 * 60;

      final totalMinutes =
      chosen.fold<int>(0, (sum, s) => sum + (s['duration'] as int));
      final needSlots = _slotsFor(totalMinutes);

      final nowMin = now.hour * 60 + now.minute;
      const lead = 10;
      final earliest = nowMin + lead;
      final latest = nowMin + _windowMinutes;

      final staffPool = _buildPool(data);
      final busy = await _busyToday(ownerId);

      for (int m = start; m < end; m += 30) {
        if (m < earliest || m > latest) continue;
        // the whole service block must finish before closing
        if (m + needSlots * 30 > end) continue;

        final free = staffPool.where((s) {
          final taken = busy[s['id']] ?? <String>{};
          for (int k = 0; k < needSlots; k++) {
            if (taken.contains(_formatSlot(m + 30 * k))) return false;
          }
          return true;
        }).toList();

        if (free.isNotEmpty) {
          final photos = data['salonPhotos'];
          return _UrgentOption(
            ownerId: ownerId,
            salonName: c['name'] as String,
            rating: _toNum(data['rating'], fallback: 0).toDouble(),
            reviewCount: (data['reviewCount'] ?? 0) as int,
            km: c['km'] as double?,
            image: data['logo'] ??
                data['profileImage'] ??
                ((photos is List && photos.isNotEmpty) ? photos.first : null),
            slotLabel: _formatSlot(m),
            slotMinutes: m,
            minutesFromNow: (m - nowMin).clamp(0, 24 * 60),
            staffId: free.first['id'] as String,
            staffName: free.first['name'].toString(),
            services: chosen,
            totalMinutes: totalMinutes,
            needSlots: needSlots,
            allStaffIds: staffPool.map((s) => s['id'] as String).toList(),
            staffNames: {
              for (final s in staffPool) s['id'] as String: s['name'].toString()
            },
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Availability check failed for ${c['ownerId']}: $e');
      return null;
    }
  }

  // Same ids / ordering as the normal booking screen's staff pool.
  List<Map<String, dynamic>> _buildPool(Map<String, dynamic> data) {
    final pool = <Map<String, dynamic>>[
      {
        'id': 'owner',
        'name': data['ownerName'] ?? data['fullName'] ?? 'Owner',
        'rating': _toNum(data['ownerStaffRating']).toDouble(),
      },
    ];
    final workers = (data['workers'] as List?) ?? [];
    for (var i = 0; i < workers.length; i++) {
      final w = workers[i];
      if (w is Map) {
        pool.add({
          'id': 'staff_$i',
          'name': w['name'] ?? 'Staff ${i + 1}',
          'rating': _toNum(w['rating']).toDouble(),
        });
      }
    }
    pool.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    return pool;
  }

  /// staffId -> set of 30-minute slot labels already occupied today.
  /// A booking blocks every slot its services' total duration covers,
  /// not just its start slot.
  Future<Map<String, Set<String>>> _busyToday(String ownerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: [
      'pending',
      'confirmed',
      'in_progress',
      'completed',
      'paid',
      'verified',
    ]).get();

    final map = <String, Set<String>>{};
    for (final doc in snapshot.docs) {
      final d = doc.data();
      final slot = (d['timeSlot'] ?? '') as String;
      if (slot.isEmpty) continue;
      final staffId = (d['staffId'] ?? 'owner') as String;

      var minutes = 0;
      for (final s in ((d['services'] as List?) ?? [])) {
        if (s is Map) minutes += _toNum(s['duration'], fallback: 30).toInt();
      }
      final n = _slotsFor(minutes);
      final startMin = _parseSlotMinutes(slot);
      final set = map.putIfAbsent(staffId, () => <String>{});
      for (int k = 0; k < n; k++) {
        set.add(_formatSlot(startMin + 30 * k));
      }
    }
    return map;
  }

  // ───────────────────────── booking ─────────────────────────

  void _openConfirmSheet(_UrgentOption option) {
    final theme = ThemeHelper(context);
    bool booking = false;
    final total =
    option.services.fold<int>(0, (sum, s) => sum + (s['price'] as int));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          return Container(
            padding: EdgeInsets.fromLTRB(
                22, 14, 22, 22 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: _urgentColor, size: 24),
                      const SizedBox(width: 6),
                      Text('urgent_confirm_title'.tr,
                          style: AppTextStyles.headingSmall
                              .copyWith(color: theme.textColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _summaryRow(Icons.storefront_rounded, 'salon'.tr,
                      option.salonName, theme),
                  _summaryRow(
                      Icons.schedule_rounded,
                      'urgent_time'.tr,
                      '${'today'.tr} · ${option.slotLabel} (${_inText(option.minutesFromNow)})',
                      theme),
                  _summaryRow(Icons.person_rounded, 'urgent_with'.tr,
                      option.staffName, theme),
                  _summaryRow(Icons.timer_outlined, 'urgent_duration'.tr,
                      '${option.totalMinutes} ${'min'.tr}', theme),
                  const SizedBox(height: 10),
                  Text('services'.tr,
                      style: AppTextStyles.label
                          .copyWith(color: theme.mutedTextColor)),
                  const SizedBox(height: 8),
                  ...option.services.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryPink, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${s['name']}',
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('${s['duration']} ${'min'.tr}',
                            style: TextStyle(
                                color: theme.mutedTextColor,
                                fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('Rs. ${s['price']}',
                            style: const TextStyle(
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _urgentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: _urgentColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('urgent_note'.tr,
                              style: TextStyle(
                                  color: theme.textColor, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('total'.tr,
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: theme.mutedTextColor)),
                      Text('Rs. $total',
                          style: AppTextStyles.headingSmall
                              .copyWith(color: AppColors.primaryPink)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: booking
                          ? null
                          : () async {
                        setSheet(() => booking = true);
                        final ok = await _createBooking(option, total);
                        if (!ok && sheetContext.mounted) {
                          setSheet(() => booking = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _urgentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: booking
                          ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4))
                          : Text('urgent_confirm_button'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(
      IconData icon, String label, String value, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryPink),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  /// Returns true when the flow ended (booked, or slot lost and refreshed).
  Future<bool> _createBooking(_UrgentOption option, int total) async {
    try {
      // Staff to try, best first: the one we showed, then everyone else.
      final candidates = <String>[
        option.staffId,
        ...option.allStaffIds.where((id) => id != option.staffId),
      ];

      final authService = Get.find<AuthService>();
      final userController = Get.find<UserController>();
      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day);

      for (final staffId in candidates) {
        final ref = FirebaseFirestore.instance.collection('bookings').doc();
        try {
          // Atomic: reserves every slot this booking needs AND creates the
          // booking. If a neighbour grabbed it a split second earlier, this
          // throws and we quietly try the next free staff member.
          await BookingLockService.createBookingWithLocks(
            bookingRef: ref,
            bookingData: {
              'bookingId': ref.id,
              'customerId': authService.uid,
              'customerName': userController.userName.value,
              'customerImage': userController.userProfileImage.value,
              'ownerId': option.ownerId,
              'salonName': option.salonName,
              'services': option.services,
              'totalPrice': total,
              'date': Timestamp.fromDate(day),
              'timeSlot': option.slotLabel,
              'staffId': staffId,
              'staffName': option.staffNames[staffId] ?? option.staffName,
              'status': 'pending',
              'isUrgent': true,
              'createdAt': FieldValue.serverTimestamp(),
            },
            ownerId: option.ownerId,
            day: day,
            staffId: staffId,
            startMinute: option.slotMinutes,
            slotCount: option.needSlots,
          );

          _notifyOwner(ref.id);
          Get.back(); // close sheet
          Get.off(() => SuccessScreen(
            bookingId: ref.id,
            dateTime: '${'today'.tr} · ${option.slotLabel}',
          ));
          return true;
        } on SlotTakenException {
          continue; // try the next staff member
        }
      }

      // Everyone is taken for that time — someone booked it just before us.
      Get.back(); // close sheet
      Get.snackbar('error'.tr, 'urgent_slot_taken'.tr);
      _findSalons();
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, '${'failed_to_book'.tr}: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  Future<void> _notifyOwner(String bookingId) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;
      await http
          .post(
        Uri.parse(_notifyNewBookingUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
          'apikey': _supabasePublishableKey,
        },
        body: jsonEncode({'bookingId': bookingId}),
      )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Urgent owner notification failed: $e');
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return PopScope(
      // From the results view, "back" returns to the service picker first.
      canPop: !_showResults,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _showResults = false;
            _searched = false;
            _searching = false;
            _results = [];
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        bottomNavigationBar: _showResults ? null : _buildBottomBar(theme),
        body: _showResults ? _buildResultsView(theme) : _buildSelectView(theme),
      ),
    );
  }

  Widget _entrance(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 8) * 70)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: c),
      ),
      child: child,
    );
  }

  // ───────────────────────── Step 1: pick services ─────────────────────────

  Widget _buildSelectView(ThemeHelper theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 26),
          _stepTitle('1', 'urgent_what_need'.tr, theme,
              trailing: _selected.isNotEmpty
                  ? GestureDetector(
                onTap: () => setState(() => _selected.clear()),
                child: Text('clear_all'.tr,
                    style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              )
                  : null),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text('urgent_pick_many'.tr,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 12.5)),
          ),
          _buildServiceGrid(theme),
          const SizedBox(height: 26),
          _buildAddOwn(theme),
          const SizedBox(height: 26),
          _stepTitle('2', 'urgent_when'.tr, theme),
          const SizedBox(height: 12),
          _buildWindowPicker(theme),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: Colors.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('urgent_hold_note'.tr,
                        style: TextStyle(
                            color: theme.mutedTextColor,
                            fontSize: 12.5,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String number, String title, ThemeHelper theme,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: _urgentColor, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: AppTextStyles.headingSmall
                    .copyWith(color: theme.textColor)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildServiceGrid(ThemeHelper theme) {
    final extra = _selected
        .where((s) =>
    !_quickServices.any((q) => q.toLowerCase() == s.toLowerCase()))
        .toList();
    final all = [..._quickServices, ...extra];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: all.map((name) {
          final active =
          _selected.any((e) => e.toLowerCase() == name.toLowerCase());
          final icon = _serviceIcons[name] ?? Icons.add_circle_outline_rounded;
          return GestureDetector(
            onTap: () => _toggleService(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: active
                    ? _urgentColor.withValues(alpha: 0.12)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: active ? _urgentColor : theme.borderColor,
                    width: active ? 2 : 1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 30,
                            color: active
                                ? _urgentColor
                                : AppColors.primaryPink),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.check_circle_rounded,
                          color: _urgentColor, size: 20),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddOwn(ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.primaryPink),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _serviceController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTypedService(),
                style:
                AppTextStyles.bodyMedium.copyWith(color: theme.textColor),
                decoration: InputDecoration(
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  border: InputBorder.none,
                  hintText: 'urgent_other_service'.tr,
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: theme.mutedTextColor),
                ),
              ),
            ),
            TextButton(
              onPressed: _addTypedService,
              child: Text('add'.tr,
                  style: const TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowPicker(ThemeHelper theme) {
    final options = <Map<String, dynamic>>[
      {'min': 60, 'sub': 'urgent_sub_fast'.tr},
      {'min': 120, 'sub': 'urgent_sub_best'.tr},
      {'min': 180, 'sub': 'urgent_sub_more'.tr},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: options.map((o) {
          final w = o['min'] as int;
          final active = _windowMinutes == w;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: w == 180 ? 0 : 10),
              child: GestureDetector(
                onTap: () => setState(() => _windowMinutes = w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryPink : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active
                            ? AppColors.primaryPink
                            : theme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Text('${w ~/ 60} ${'hr'.tr}',
                          style: TextStyle(
                              color: active ? Colors.white : theme.textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(o['sub'] as String,
                          style: TextStyle(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : theme.mutedTextColor,
                              fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Sticky bottom bar: always visible, tells the user what to do next.
  Widget _buildBottomBar(ThemeHelper theme) {
    final count = _selected.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 0
                      ? 'urgent_select_hint'.tr
                      : '$count ${'urgent_selected_n'.tr}',
                  style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                if (count > 0)
                  Text(
                    _selected.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    TextStyle(color: theme.mutedTextColor, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // THE FIX: IntrinsicWidth forces the button to only be as wide as its content
          IntrinsicWidth(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: count == 0 ? null : _findSalons,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _urgentColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text('urgent_find_button'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Step 2: results ─────────────────────────

  Widget _buildResultsView(ThemeHelper theme) {
    return Column(
      children: [
        _buildResultsHeader(theme),
        Expanded(
          child: _searching
              ? _buildSearching(theme)
              : (_searched && _results.isEmpty)
              ? _buildEmpty(theme)
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            itemCount: _results.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${_results.length} ${'urgent_available'.tr}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: theme.mutedTextColor),
                  ),
                );
              }
              return _entrance(
                  i, _buildResultCard(_results[i - 1], theme));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(ThemeHelper theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _showResults = false;
                  _searched = false;
                  _searching = false;
                  _results = [];
                }),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: theme.textColor, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('urgent_results_title'.tr,
                    style: AppTextStyles.headingSmall
                        .copyWith(color: theme.textColor)),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _showResults = false;
                  _searched = false;
                  _searching = false;
                  _results = [];
                }),
                icon: const Icon(Icons.tune_rounded,
                    size: 16, color: AppColors.primaryPink),
                label: Text('urgent_edit'.tr,
                    style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // what was searched
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in _selected)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _urgentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            color: _urgentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // switch time window without going back
          Row(
            children: [
              Text('urgent_within'.tr,
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 12.5)),
              const SizedBox(width: 10),
              for (final w in const [60, 120, 180])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (_windowMinutes == w) return;
                      setState(() => _windowMinutes = w);
                      _findSalons();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _windowMinutes == w
                            ? AppColors.primaryPink
                            : theme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _windowMinutes == w
                                ? AppColors.primaryPink
                                : theme.borderColor),
                      ),
                      child: Text('${w ~/ 60} ${'hr'.tr}',
                          style: TextStyle(
                              color: _windowMinutes == w
                                  ? Colors.white
                                  : theme.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeHelper theme) {
    final radius = SearchRadiusController.instance;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slim top bar: round back button + small label
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: theme.textColor, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _urgentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: _urgentColor, size: 16),
                    const SizedBox(width: 4),
                    Text('urgent_badge'.tr,
                        style: const TextStyle(
                            color: _urgentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.6)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('urgent_title'.tr,
              style: AppTextStyles.headingLarge.copyWith(
                  color: theme.textColor, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('urgent_subtitle'.tr,
              style: TextStyle(
                  color: theme.mutedTextColor, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          Obx(() => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill(Icons.near_me_rounded,
                  '${'within'.tr} ${radius.km.value} km', theme),
              _infoPill(Icons.event_available_rounded,
                  'urgent_pill_today'.tr, theme),
              _infoPill(Icons.notifications_active_rounded,
                  'urgent_pill_priority'.tr, theme),
            ],
          )),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, ThemeHelper theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _urgentColor),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildSearching(ThemeHelper theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                  color: _urgentColor, strokeWidth: 3.2),
            ),
            const SizedBox(height: 18),
            Text(_progress,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.mutedTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeHelper theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 60, color: theme.mutedTextColor),
            const SizedBox(height: 14),
            Text('urgent_none_title'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.headingSmall
                    .copyWith(color: theme.textColor)),
            const SizedBox(height: 8),
            Text('urgent_none_body'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: theme.mutedTextColor)),
            const SizedBox(height: 18),
            if (_windowMinutes < 180)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _windowMinutes = 180);
                  _findSalons();
                },
                icon: const Icon(Icons.schedule_rounded,
                    color: AppColors.primaryPink),
                label: Text('urgent_try_3h'.tr,
                    style: const TextStyle(color: AppColors.primaryPink)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryPink),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(_UrgentOption o, ThemeHelper theme) {
    final img = _imageProvider(o.image);
    final totalPrice =
    o.services.fold<int>(0, (sum, s) => sum + (s['price'] as int));
    final soon = o.minutesFromNow <= 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openConfirmSheet(o),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.borderColor),
              boxShadow: [theme.softShadow],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 62,
                        height: 62,
                        color: theme.lightPinkColor,
                        child: img != null
                            ? Image(image: img, fit: BoxFit.cover)
                            : const Icon(Icons.storefront_rounded,
                            color: AppColors.primaryPink, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.salonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 2),
                              Text(o.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              if (o.km != null) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.near_me_rounded,
                                    size: 14, color: theme.mutedTextColor),
                                const SizedBox(width: 3),
                                Text('${o.km!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                        color: theme.mutedTextColor,
                                        fontSize: 13)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: (soon ? Colors.green : _urgentColor)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 18, color: soon ? Colors.green : _urgentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${o.slotLabel} · ${_inText(o.minutesFromNow)}',
                          style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5),
                        ),
                      ),
                      Text('Rs. $totalPrice · ${o.totalMinutes} ${'min'.tr}',
                          style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _openConfirmSheet(o),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _urgentColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('urgent_book_now'.tr,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UrgentOption {
  final String ownerId;
  final String salonName;
  final double rating;
  final int reviewCount;
  final double? km;
  final dynamic image;
  final String slotLabel;
  final int slotMinutes;
  final int minutesFromNow;
  final String staffId;
  final String staffName;
  final List<Map<String, dynamic>> services;
  final List<String> allStaffIds;
  final Map<String, String> staffNames;
  final int totalMinutes;
  final int needSlots;

  _UrgentOption({
    required this.ownerId,
    required this.salonName,
    required this.rating,
    required this.reviewCount,
    required this.km,
    required this.image,
    required this.slotLabel,
    required this.slotMinutes,
    required this.minutesFromNow,
    required this.staffId,
    required this.staffName,
    required this.services,
    required this.allStaffIds,
    required this.staffNames,
    required this.totalMinutes,
    required this.needSlots,
  });
}

/// Premium open animation matching the search screen.
Route<T> urgentRoute<T>() {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const UrgentBookingScreen(),
    transitionsBuilder: (_, animation, __, child) {
      final curved =
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}
