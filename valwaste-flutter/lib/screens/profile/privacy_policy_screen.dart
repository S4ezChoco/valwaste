import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Your Privacy Matters',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateTime.now().year}',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),

            // Content Sections
            _buildSection(
              title: '1. Information We Collect',
              content: '''We collect information you provide directly to us, such as:

• Personal information (name, email, phone number)
• Location data for waste collection services
• Account credentials and preferences
• Collection requests and feedback

We also automatically collect certain information when you use our app:
• Device information and identifiers
• Usage data and app interactions
• Location data (with your permission)
• Log files and crash reports''',
            ),

            _buildSection(
              title: '2. How We Use Your Information',
              content: '''We use the information we collect to:

• Provide and improve our waste collection services
• Process and manage collection requests
• Send notifications about collection schedules
• Communicate with you about our services
• Ensure the security of our platform
• Comply with legal obligations
• Analyze usage patterns to improve user experience''',
            ),

            _buildSection(
              title: '3. Information Sharing',
              content: '''We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:

• With waste collection personnel to fulfill service requests
• With local government authorities as required by law
• With service providers who assist in app operations
• In case of emergency or public safety concerns
• With your explicit consent''',
            ),

            _buildSection(
              title: '4. Data Security',
              content: '''We implement appropriate security measures to protect your information:

• Encryption of sensitive data in transit and at rest
• Regular security assessments and updates
• Access controls and authentication measures
• Secure data storage with Firebase
• Regular backups and disaster recovery procedures

However, no method of transmission over the internet is 100% secure.''',
            ),

            _buildSection(
              title: '5. Location Data',
              content: '''ValWaste uses location data to:

• Determine your service area and barangay
• Optimize collection routes and schedules
• Provide accurate service delivery
• Show nearby collection points on maps

You can control location permissions through your device settings. Disabling location services may limit app functionality.''',
            ),

            _buildSection(
              title: '6. Data Retention',
              content: '''We retain your information for as long as necessary to:

• Provide our services to you
• Comply with legal obligations
• Resolve disputes and enforce agreements
• Improve our services

You may request deletion of your account and associated data at any time.''',
            ),

            _buildSection(
              title: '7. Your Rights',
              content: '''You have the right to:

• Access your personal information
• Correct inaccurate information
• Request deletion of your data
• Withdraw consent for data processing
• Receive a copy of your data
• File complaints with relevant authorities''',
            ),

            _buildSection(
              title: '8. Children\'s Privacy',
              content: '''ValWaste is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will take steps to delete it promptly.''',
            ),

            _buildSection(
              title: '9. Changes to This Policy',
              content: '''We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app and updating the "Last updated" date. Your continued use of the app after changes constitutes acceptance of the updated policy.''',
            ),

            _buildSection(
              title: '10. Contact Us',
              content: '''If you have any questions about this Privacy Policy or our data practices, please contact us:

• Through the app's Help & Support section
• Email: privacy@valwaste.gov.ph
• Address: Valenzuela City Hall, Valenzuela City, Metro Manila

We will respond to your inquiries within 30 days.''',
            ),

            const SizedBox(height: AppSizes.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            content,
            style: AppTextStyles.body1.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
