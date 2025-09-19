import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;

  late TabController _tabController;

  final List<Map<String, dynamic>> _scheduleCategories = [
    {
      'title': 'GABI-GABI (MAJOR ROADS)',
      'subtitle': 'Every Night - Major Roads',
      'icon': Icons.route,
      'color': Colors.blue,
      'locations': [
        'MacArthur Highway',
        'Karuhatan - Gen. T. De Leon - Santolan - M. Delos Reyes - Parafort - Capt.',
        'Cruz Parada - S. De Guzman Parada - Parada Road',
        'T. Santiago Road',
        'Governor I. Santiago - Rincon - Pasolo Road - G. Lazaro Road',
        'Maysan - Paso De Blas - Bisalao Bagbaguin - ITC Compound - Malinis',
        'Sapang Bakaw - Lawang Bato - F. Faustino - Ibaba Bignay (Disiplina)',
        'M.H. Del Pilar (Malanday - Arkong Bato)',
        'Sto. Rosario Mapulang Lupa - Binatugan - Que Grande Bridge Ugong',
        'Tagalag Road',
        'All Service Roads',
      ],
    },
    {
      'title': 'GABI-GABI (MGA PALENGKE)',
      'subtitle': 'Every Night - Markets',
      'icon': Icons.store,
      'color': Colors.orange,
      'locations': [
        'Polo Market',
        'Malanday Kadiwa',
        'Malanday M.H. Del Pilar',
        'Dalandanan Market',
        'Lorex Market Gen. T. De Leon',
        'Karuhatan Market',
        'Marulas Market',
        'Fortune Market (Disiplina Bignay)',
      ],
    },
    {
      'title': 'ARAW-ARAW (6:00 AM)',
      'subtitle': 'Every Day - 6:00 AM',
      'icon': Icons.wb_sunny,
      'color': Colors.green,
      'locations': [
        'MacArthur Highway (Dalandanan - Riverside; A. Pablo Karuhatan - Marulas)',
        'Pio Valenzuela',
        'Gen. T. De Leon Road',
        'Maysan - Paso De Blas - Bisalao',
        'Bagbaguin',
        'T. Santiago',
        'M.H. Del Pilar',
        'Governor I. Santiago Malinta - Daffodil - Tangke Outpost cor. Santos St.',
        'Malinta - Balubaran Road - Maysan (OLFU)',
        'Rincon - Pasolo - G. Lazaro - M.H. Del Pilar - Polo - Balangkas (Arko) - Palasan Arkong Bato (San Diego)',
        'JB Juan - B Juan - Binatugan - Tatalon - Mindanao Ave. - Sto. Rosario - Bisalao - Mapulang Lupa - West Service Road',
        'East Service Road Canumay East - Sapang Bakaw - WES Arena - Sitio Centro - Malinis',
        'Punturin - Bignay Galas Talipapa - Gitna Bignay (Andoks) - All Day Bignay',
        'R. Valenzuela Extension - T. Concepcion Marulas - Abalos - Gumamela - Urrutia Gen. T. De Leon',
        'Capt. Cruz - S. De Guzman - P. De Guzman - Fortune 7 - Parada Road - Patio Queen Sofia Maysan',
      ],
    },
  ];

  final List<Map<String, String>> _barangaySchedules = [
    {'barangay': 'Arkong Bato', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Bagbaguin', 'schedule': 'Tuesday - Friday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Balankas', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Bignay', 'schedule': 'Monday - Thursday', 'inspector': 'Jesus Moscaya'},
    {'barangay': 'Bisig', 'schedule': 'Monday - Thursday', 'inspector': 'Romano Roque'},
    {'barangay': 'Canumay East', 'schedule': 'Monday - Thursday', 'inspector': 'Norman Bautista'},
    {'barangay': 'Canumay West', 'schedule': 'Tuesday - Friday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Coloong', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Dalandanan', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Gen T. De Leon', 'schedule': 'Wednesday - Saturday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Isla', 'schedule': 'Monday - Thursday', 'inspector': 'Romano Roque'},
    {'barangay': 'Karuhatan', 'schedule': 'Wednesday - Saturday', 'inspector': 'Norman Bautista'},
    {'barangay': 'Lawang Bato', 'schedule': 'Monday - Thursday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Lingunan', 'schedule': 'Monday - Thursday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Mabolo', 'schedule': 'Monday - Thursday', 'inspector': 'Romano Roque'},
    {'barangay': 'Malanday', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Malinta', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Mapulang Lupa', 'schedule': 'Tuesday - Friday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Marulas', 'schedule': 'Wednesday - Saturday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Maysan', 'schedule': 'Tuesday - Friday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Palasan', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Parada', 'schedule': 'Tuesday - Friday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Parianciano Villa', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Paso De Blas', 'schedule': 'Monday - Thursday', 'inspector': 'Norman Bautista'},
    {'barangay': 'Pasolo', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Poblacion', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Pulo', 'schedule': 'Tuesday - Friday', 'inspector': 'Romano Roque'},
    {'barangay': 'Punturin', 'schedule': 'Monday - Thursday', 'inspector': 'Jesus Moscaya'},
    {'barangay': 'Rincon', 'schedule': 'Monday - Thursday', 'inspector': 'Reynaldo Pajima Jr.'},
    {'barangay': 'Tagalag', 'schedule': 'Monday - Thursday', 'inspector': 'Romano Roque'},
    {'barangay': 'Ugong', 'schedule': 'Tuesday - Friday', 'inspector': 'Norman Bautista'},
    {'barangay': 'Viente Reales', 'schedule': 'Monday - Thursday', 'inspector': 'Ronelo Crame'},
    {'barangay': 'Wawang Pulo', 'schedule': 'Monday - Thursday', 'inspector': 'Romano Roque'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TALATAKDAAN NG HAKOT NG BASURA',
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Valenzuela City Waste Collection Schedule',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.route, size: 20),
                    text: 'GENERAL SCHEDULE',
                  ),
                  Tab(
                    icon: Icon(Icons.location_city, size: 20),
                    text: 'BARANGAY SCHEDULE',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // General Schedule Tab
                  _buildGeneralScheduleTab(),
                  // Barangay Schedule Tab
                  _buildBarangayScheduleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralScheduleTab() {
    return Column(
      children: [
        // Category Selector
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _scheduleCategories.length,
            itemBuilder: (context, index) {
              final category = _scheduleCategories[index];
              final isSelected = _selectedCategoryIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? category['color'] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? category['color'] : AppColors.divider,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.white : category['color'],
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category['title'].split(' ')[0],
                        style: AppTextStyles.body2.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Schedule Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Category Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _scheduleCategories[_selectedCategoryIndex]['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _scheduleCategories[_selectedCategoryIndex]['color'].withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _scheduleCategories[_selectedCategoryIndex]['icon'],
                            color: _scheduleCategories[_selectedCategoryIndex]['color'],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _scheduleCategories[_selectedCategoryIndex]['title'],
                              style: AppTextStyles.heading3.copyWith(
                                color: _scheduleCategories[_selectedCategoryIndex]['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scheduleCategories[_selectedCategoryIndex]['subtitle'],
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Locations List
                ..._scheduleCategories[_selectedCategoryIndex]['locations']
                    .map<Widget>((location) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _scheduleCategories[_selectedCategoryIndex]['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarangayScheduleTab() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.location_city, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WASTE COLLECTION SCHEDULE',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Barangay Collection Days',
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'BARANGAY',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'SCHEDULE',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Schedule List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _barangaySchedules.length,
            itemBuilder: (context, index) {
              final schedule = _barangaySchedules[index];
              final isEven = index % 2 == 0;
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : AppColors.background,
                  border: Border(
                    left: BorderSide(color: AppColors.divider.withOpacity(0.3)),
                    right: BorderSide(color: AppColors.divider.withOpacity(0.3)),
                    bottom: BorderSide(
                      color: AppColors.divider.withOpacity(0.3),
                      width: index == _barangaySchedules.length - 1 ? 1 : 0.5,
                    ),
                  ),
                  borderRadius: index == _barangaySchedules.length - 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // Barangay Name
                    Expanded(
                      flex: 1,
                      child: Text(
                        schedule['barangay']!,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Schedule
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          schedule['schedule']!,
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Footer Info
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please prepare your waste according to your barangay\'s collection schedule.',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
