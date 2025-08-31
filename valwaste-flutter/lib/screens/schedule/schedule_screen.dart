import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedCategoryIndex = 0;

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
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
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
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Valenzuela City Waste Collection Schedule',
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

            // Category Selector
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingSmall,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                ),
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
                      width: 140,
                      margin: const EdgeInsets.only(
                        right: AppSizes.paddingSmall,
                      ),
                      padding: const EdgeInsets.all(AppSizes.paddingSmall),
                      decoration: BoxDecoration(
                        color: isSelected ? category['color'] : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? category['color']
                              : AppColors.divider,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected
                                ? Colors.white
                                : category['color'],
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['title'].split(' ')[0], // First word
                            style: AppTextStyles.body2.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
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
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  children: [
                    // Category Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color:
                            _scheduleCategories[_selectedCategoryIndex]['color']
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        border: Border.all(
                          color:
                              _scheduleCategories[_selectedCategoryIndex]['color']
                                  .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _scheduleCategories[_selectedCategoryIndex]['icon'],
                                color:
                                    _scheduleCategories[_selectedCategoryIndex]['color'],
                                size: 24,
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Expanded(
                                child: Text(
                                  _scheduleCategories[_selectedCategoryIndex]['title'],
                                  style: AppTextStyles.heading3.copyWith(
                                    color:
                                        _scheduleCategories[_selectedCategoryIndex]['color'],
                                    fontWeight: FontWeight.bold,
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
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSizes.paddingMedium),

                    // Locations List
                    ..._scheduleCategories[_selectedCategoryIndex]['locations']
                        .map<Widget>((location) {
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSizes.paddingSmall,
                            ),
                            padding: const EdgeInsets.all(
                              AppSizes.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                              border: Border.all(color: AppColors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _scheduleCategories[_selectedCategoryIndex]['color'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.paddingMedium),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),

                    const SizedBox(height: AppSizes.paddingLarge),

                    // Footer Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Text(
                                'WASTE MANAGEMENT DIVISION',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Please ensure your waste is properly sorted and placed outside for collection. Keep our city clean!',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
