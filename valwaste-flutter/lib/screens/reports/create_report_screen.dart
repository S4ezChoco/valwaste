import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/report_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Missed Collection';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Missed Collection',
    'Illegal Dumping',
    'Damaged Equipment',
    'Complaint',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReportService.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Create Report',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report an Issue',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                'Your report will be reviewed by barangay officials',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  prefixIcon: Icon(Icons.title, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  prefixIcon: Icon(Icons.category, color: AppColors.primary),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where is the issue located?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide detailed information about the issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description, color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),

              // Photo Upload Button (placeholder)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement photo upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload coming soon'),
                    ),
                  );
                },
                icon: Icon(Icons.camera_alt, color: AppColors.primary),
                label: Text(
                  'Add Photo (Optional)',
                  style: TextStyle(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLarge),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
