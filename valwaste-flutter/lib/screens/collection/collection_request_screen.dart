import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/barangay_data.dart';
import '../../models/waste_collection.dart';
import '../../models/user.dart';
import '../../services/advanced_scheduling_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/location_service.dart';
import '../map/map_picker_screen.dart';

class CollectionRequestScreen extends StatefulWidget {
  const CollectionRequestScreen({super.key});

  @override
  State<CollectionRequestScreen> createState() =>
      _CollectionRequestScreenState();
}

class _CollectionRequestScreenState extends State<CollectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  WasteType _selectedWasteType = WasteType.general;
  double _estimatedWeight = 5.0;
  bool _isLoading = false;
  bool _isUrgent = false;

  // Priority and Category fields
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Collection Request';

  // Available options
  final List<String> _priorityOptions = ['High', 'Medium', 'Low'];
  final List<String> _categoryOptions = [
    'Collection Request',
    'Missed Collection',
    'Illegal Dumping',
    'Complaint',
  ];

  // Location variables
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isGettingLocation = false;

  // Enhanced features
  bool _showCollectionTips = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Helper methods for enhanced UI
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  IconData _getWasteTypeIcon(WasteType wasteType) {
    switch (wasteType) {
      case WasteType.general:
        return Icons.delete;
      case WasteType.recyclable:
        return Icons.recycling;
      case WasteType.organic:
        return Icons.eco;
      case WasteType.hazardous:
        return Icons.warning;
      case WasteType.electronic:
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.priority_high;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Collection Request':
        return Icons.recycling;
      case 'Missed Collection':
        return Icons.schedule;
      case 'Illegal Dumping':
        return Icons.warning;
      case 'Complaint':
        return Icons.feedback;
      default:
        return Icons.category;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if GPS tracking is enabled
      final canAccess = await LocationService.canAccessLocation();
      if (!canAccess) {
        final isEnabled = await LocationService.isGpsTrackingEnabled();
        if (!isEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'GPS tracking is disabled in settings. Please enable it to use location features.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission is required to automatically fill your address',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position using the location service
      final position = await LocationService.getCurrentLocationIfEnabled();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to get current location. Please check your settings.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _isGettingLocation = false;
      });

      // Auto-fill address field with nearest barangay name
      if (mounted) {
        final nearestBarangay = BarangayData.getNearestBarangay(
          position.latitude, 
          position.longitude
        );
        _addressController.text = nearestBarangay;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location captured! Nearest location: $nearestBarangay',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            initialLatitude: _currentLatitude,
            initialLongitude: _currentLongitude,
            initialAddress: _addressController.text.isNotEmpty
                ? _addressController.text
                : null,
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _currentLatitude = result['latitude'];
          _currentLongitude = result['longitude'];
          _addressController.text = result['address'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error opening map picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map picker: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is a resident
    final currentUser = FirebaseAuthService.currentUser;
    if (currentUser != null && currentUser.role != UserRole.resident) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 80, color: AppColors.error),
                const SizedBox(height: AppSizes.paddingLarge),
                Text(
                  'Access Restricted',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Only residents can make collection requests.',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'Your role: ${currentUser.roleString}',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLarge,
                      vertical: AppSizes.paddingMedium,
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.recycling, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Request Collection',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.9),
                const Color(0xFF2E7D32),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fill out the form below to request waste collection',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSmall,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
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
                              'Schedule Waste Collection',
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Request a pickup for your waste',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Collection Tips Toggle
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Text(
                          'Collection Tips',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showCollectionTips,
                        onChanged: (value) {
                          setState(() {
                            _showCollectionTips = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Collection Tips Content
                if (_showCollectionTips) ...[
                  const SizedBox(height: AppSizes.paddingMedium),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusMedium,
                      ),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Collection Tips',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        _buildTipItem(
                          'Separate waste by type for better processing',
                        ),
                        _buildTipItem(
                          'Ensure waste is properly bagged and sealed',
                        ),
                        _buildTipItem('Place waste in an accessible location'),
                        _buildTipItem(
                          'Avoid overfilling bags to prevent spillage',
                        ),
                        _buildTipItem(
                          'Mark hazardous waste clearly for safety',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                ],

                // Waste Type Selection
                Text(
                  'Waste Type',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: WasteType.values.map((wasteType) {
                      final wasteTypeString = wasteType.name;
                      final wasteName =
                          WasteTypeData.wasteTypes[wasteTypeString]!;
                      final wasteColor =
                          WasteTypeData.wasteTypeColors[wasteTypeString]!;
                      final wasteIcon =
                          WasteTypeData.wasteTypeIcons[wasteTypeString]!;

                      return RadioListTile<WasteType>(
                        value: wasteType,
                        groupValue: _selectedWasteType,
                        onChanged: (value) {
                          setState(() {
                            _selectedWasteType = value!;
                          });
                        },
                        title: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: wasteColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusSmall,
                                ),
                              ),
                              child: Icon(
                                wasteIcon,
                                color: wasteColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Text(
                              wasteName,
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Estimated Weight
                Text(
                  'Estimated Weight (kg)',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Slider(
                        value: _estimatedWeight,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _estimatedWeight = value;
                          });
                        },
                      ),
                      Text(
                        '${_estimatedWeight.toStringAsFixed(1)} kg',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Address Input
                Row(
                  children: [
                    Text(
                      'Collection Address',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_currentLatitude != null && _currentLongitude != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Location Captured',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your address for collection',
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isGettingLocation
                          ? null
                          : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        _isGettingLocation ? 'Getting...' : 'Get Location',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Pick on Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Location coordinates indicator
                if (_currentLatitude != null && _currentLongitude != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location coordinates: ${_currentLatitude!.toStringAsFixed(6)}, ${_currentLongitude!.toStringAsFixed(6)}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Description Input
                Text(
                  'Additional Notes',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Any special instructions or notes...',
                    prefixIcon: Icon(Icons.note, color: AppColors.primary),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Priority Selection
                Text(
                  'Priority',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: _priorityOptions.map((priority) {
                      return RadioListTile<String>(
                        title: Text(priority),
                        value: priority,
                        groupValue: _selectedPriority,
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Category Selection
                Text(
                  'Category',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: _categoryOptions.map((category) {
                      return RadioListTile<String>(
                        title: Text(category),
                        value: category,
                        groupValue: _selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        activeColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Urgent Collection Checkbox
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: _isUrgent ? Colors.red : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urgent Collection',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _isUrgent
                                    ? Colors.red
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Mark as urgent for priority scheduling',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isUrgent,
                        onChanged: (value) {
                          setState(() {
                            _isUrgent = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLarge),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send),
                              const SizedBox(width: AppSizes.paddingSmall),
                              Text(
                                'Submit Request',
                                style: AppTextStyles.button,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTextStyles.body2.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.body2.copyWith(color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AdvancedSchedulingService.scheduleCollection(
        wasteType: _selectedWasteType,
        quantity: _estimatedWeight,
        unit: 'kg',
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        barangay: 'Valenzuela City', // Default barangay
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        notes: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        isUrgent: _isUrgent,
        priority: _selectedPriority,
        category: _selectedCategory,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.success,
            ),
          );
          // Add a small delay to ensure data is saved before navigating back
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
