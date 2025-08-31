import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/recycling_guide.dart';

class RecyclingGuideScreen extends StatefulWidget {
  const RecyclingGuideScreen({super.key});

  @override
  State<RecyclingGuideScreen> createState() => _RecyclingGuideScreenState();
}

class _RecyclingGuideScreenState extends State<RecyclingGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'General Waste',
    'Recyclable',
    'Organic',
    'Hazardous',
    'Electronic',
  ];

  final List<RecyclingGuide> _guides = [
    RecyclingGuide(
      id: '1',
      title: 'Plastic Bottles',
      description: 'How to properly recycle plastic bottles',
      category: 'Recyclable',
      instructions: [
        'Rinse the bottle thoroughly',
        'Remove the cap and label',
        'Crush the bottle to save space',
        'Place in recycling bin',
      ],
      tips: [
        'Check the recycling number on the bottom',
        'Only recycle clean bottles',
        'Don\'t recycle bottles that contained motor oil or chemicals',
      ],
      imageUrl: null,
      isRecyclable: true,
      disposalMethod: 'Recycling Bin',
    ),
    RecyclingGuide(
      id: '2',
      title: 'Paper and Cardboard',
      description: 'Proper disposal of paper products',
      category: 'Recyclable',
      instructions: [
        'Remove any plastic or metal attachments',
        'Flatten cardboard boxes',
        'Keep paper dry and clean',
        'Separate by type (newspaper, office paper, etc.)',
      ],
      tips: [
        'Don\'t recycle greasy pizza boxes',
        'Shred sensitive documents before recycling',
        'Remove plastic windows from envelopes',
      ],
      imageUrl: null,
      isRecyclable: true,
      disposalMethod: 'Recycling Bin',
    ),
    RecyclingGuide(
      id: '3',
      title: 'Food Waste',
      description: 'Composting organic waste',
      category: 'Organic',
      instructions: [
        'Collect food scraps in a compost bin',
        'Add yard waste like leaves and grass',
        'Turn the compost regularly',
        'Keep it moist but not wet',
      ],
      tips: [
        'Avoid meat and dairy in home composting',
        'Chop large pieces for faster decomposition',
        'Use finished compost in your garden',
      ],
      imageUrl: null,
      isRecyclable: true,
      disposalMethod: 'Composting',
    ),
    RecyclingGuide(
      id: '4',
      title: 'Batteries',
      description: 'Safe disposal of batteries',
      category: 'Hazardous',
      instructions: [
        'Do not throw in regular trash',
        'Collect used batteries in a container',
        'Take to designated collection points',
        'Check for local battery recycling programs',
      ],
      tips: [
        'Store batteries in a cool, dry place',
        'Don\'t mix different battery types',
        'Consider rechargeable batteries',
      ],
      imageUrl: null,
      isRecyclable: false,
      disposalMethod: 'Special Collection',
    ),
    RecyclingGuide(
      id: '5',
      title: 'Electronics',
      description: 'E-waste disposal guidelines',
      category: 'Electronic',
      instructions: [
        'Remove personal data from devices',
        'Don\'t throw in regular trash',
        'Find local e-waste collection centers',
        'Check manufacturer take-back programs',
      ],
      tips: [
        'Donate working electronics',
        'Sell valuable components',
        'Look for certified e-waste recyclers',
      ],
      imageUrl: null,
      isRecyclable: true,
      disposalMethod: 'E-Waste Collection',
    ),
  ];

  List<RecyclingGuide> get _filteredGuides {
    return _guides.where((guide) {
      final matchesSearch =
          guide.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guide.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || guide.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recycling Guide'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recycling guides...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),

                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: AppSizes.paddingSmall,
                          ),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Results Count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              child: Text(
                '${_filteredGuides.length} guides found',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Guides List
            Expanded(
              child: _filteredGuides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          Text(
                            'No guides found',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Try adjusting your search or filters',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      itemCount: _filteredGuides.length,
                      itemBuilder: (context, index) {
                        final guide = _filteredGuides[index];
                        return _buildGuideCard(guide);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard(RecyclingGuide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: guide.isRecyclable
                ? AppColors.success.withOpacity(0.2)
                : AppColors.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Icon(
            guide.isRecyclable ? Icons.recycling : Icons.warning,
            color: guide.isRecyclable ? AppColors.success : AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          guide.title,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.paddingSmall),
            Text(guide.description, style: AppTextStyles.body2),
            const SizedBox(height: AppSizes.paddingSmall),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                guide.category,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Text(
                  'Instructions:',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                ...guide.instructions.map(
                  (instruction) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.paddingSmall,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(
                          child: Text(instruction, style: AppTextStyles.body2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingMedium),

                // Tips
                Text(
                  'Tips:',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                ...guide.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.paddingSmall,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(child: Text(tip, style: AppTextStyles.body2)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingMedium),

                // Disposal Method
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disposal Method:',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              guide.disposalMethod ?? 'Not specified',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
