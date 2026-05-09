import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_helper.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Upcoming', 'Completed', 'Cancelled'];

  final List<Map<String, dynamic>> _upcoming = [
    {
      'salon': 'Royal Cuts Studio',
      'date': 'Tue 29 Apr · 10:00 AM',
      'services': ['Haircut', 'Beard'],
      'price': 'Rs.700',
      'status': 'Confirmed',
    },
    {
      'salon': 'Glamour Zone',
      'date': 'Wed 30 Apr · 2:00 PM',
      'services': ['Facial'],
      'price': 'Rs.800',
      'status': 'Pending',
    },
  ];

  final List<Map<String, dynamic>> _completed = [
    {
      'salon': 'The Barber Guild',
      'date': 'Mon 15 Apr · 11:00 AM',
      'services': ['Classic Cut'],
      'price': 'Rs.600',
      'status': 'Completed',
    },
    {
      'salon': 'Royal Cuts Studio',
      'date': 'Mon 1 Apr · 3:00 PM',
      'services': ['Haircut', 'Facial'],
      'price': 'Rs.1,300',
      'status': 'Completed',
    },
  ];

  final List<Map<String, dynamic>> _cancelled = [
    {
      'salon': 'Elite Hair Studio',
      'date': 'Fri 5 Apr · 5:00 PM',
      'services': ['Hair Color'],
      'price': 'Rs.1,000',
      'status': 'Cancelled',
    },
  ];

  List<Map<String, dynamic>> get _currentList {
    if (_selectedTab == 0) return _upcoming;
    if (_selectedTab == 1) return _completed;
    return _cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Bookings', style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Tabs
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 4,
                          right: i == _tabs.length - 1 ? 0 : 4,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: selected ? theme.cardColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selected
                                  ? [
                                BoxShadow(
                                  color: AppColors.primaryPink.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[i],
                              style: AppTextStyles.label.copyWith(
                                color: selected ? AppColors.primaryPink : theme.mutedTextColor,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: _currentList.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 48, color: theme.borderColor),
                      const SizedBox(height: 12),
                      Text('No bookings here', style: AppTextStyles.bodyMedium?.copyWith(color: theme.mutedTextColor)),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: _currentList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = _currentList[index];
                    final isUpcoming = _selectedTab == 0;
                    final isCompleted = _selectedTab == 1;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [theme.softShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: theme.lightPinkColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.content_cut_rounded, size: 20, color: AppColors.primaryPink),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['salon'], style: AppTextStyles.cardTitle?.copyWith(color: theme.textColor)),
                                    const SizedBox(height: 2),
                                    Text(b['date'], style: AppTextStyles.label?.copyWith(color: theme.mutedTextColor)),
                                  ],
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: b['status'] == 'Confirmed'
                                      ? AppColors.successBg
                                      : b['status'] == 'Pending'
                                      ? theme.lightPinkColor
                                      : b['status'] == 'Cancelled'
                                      ? const Color(0xFFFFF0F0)
                                      : theme.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  b['status'],
                                  style: AppTextStyles.label.copyWith(
                                    color: b['status'] == 'Confirmed'
                                        ? AppColors.success
                                        : b['status'] == 'Pending'
                                        ? AppColors.primaryPink
                                        : b['status'] == 'Cancelled'
                                        ? Colors.red
                                        : theme.mutedTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Divider(height: 1, color: theme.borderColor),
                          const SizedBox(height: 10),

                          // Service tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (b['services'] as List<String>)
                                .map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.lightPinkColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(s,
                                  style: AppTextStyles.label.copyWith(
                                      color: AppColors.primaryPink, fontWeight: FontWeight.w600)),
                            ))
                                .toList(),
                          ),

                          const SizedBox(height: 10),

                          // Price + actions
                          Row(
                            children: [
                              Text(b['price'],
                                  style: AppTextStyles.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.textColor,
                                  )),
                              const Spacer(),
                              if (isUpcoming) ...[
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: theme.borderColor),
                                    ),
                                    child: Text('Cancel',
                                        style: AppTextStyles.label.copyWith(
                                            color: theme.mutedTextColor, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primaryPink, AppColors.darkPink],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('Reschedule',
                                        style: AppTextStyles.label.copyWith(
                                            color: Colors.white, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                              if (isCompleted)
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primaryPink, AppColors.darkPink],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('Book Again',
                                        style: AppTextStyles.label.copyWith(
                                            color: Colors.white, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}