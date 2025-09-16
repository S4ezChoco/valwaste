import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Terms and Conditions',
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
                      Icons.description,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'Terms of Service',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Effective Date: ${DateTime.now().year}',
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
              title: '1. Acceptance of Terms',
              content: '''By downloading, installing, or using the ValWaste mobile application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our service.

These terms constitute a legally binding agreement between you and the City Government of Valenzuela regarding your use of the ValWaste waste collection management system.''',
            ),

            _buildSection(
              title: '2. Service Description',
              content: '''ValWaste is a waste collection management application that provides:

• Waste collection request submission
• Collection schedule notifications
• Real-time tracking of collection services
• Communication with waste collection personnel
• Reporting and feedback mechanisms
• Educational resources on waste management

The service is provided by the City Government of Valenzuela to improve waste management efficiency within the city.''',
            ),

            _buildSection(
              title: '3. User Eligibility',
              content: '''To use ValWaste, you must:

• Be at least 13 years of age
• Be a resident or have legitimate business within Valenzuela City
• Provide accurate and complete registration information
• Maintain the security of your account credentials
• Comply with all applicable local laws and regulations''',
            ),

            _buildSection(
              title: '4. User Responsibilities',
              content: '''As a user of ValWaste, you agree to:

• Provide accurate information when submitting collection requests
• Use the service only for legitimate waste collection purposes
• Respect collection schedules and personnel
• Properly segregate waste according to city guidelines
• Report any issues or concerns through appropriate channels
• Not misuse or abuse the service in any way
• Keep your account information up to date''',
            ),

            _buildSection(
              title: '5. Prohibited Activities',
              content: '''You may not use ValWaste to:

• Submit false or fraudulent collection requests
• Harass or threaten collection personnel
• Interfere with the normal operation of the service
• Attempt to gain unauthorized access to the system
• Use the service for commercial waste without proper permits
• Share your account credentials with others
• Violate any applicable laws or regulations''',
            ),

            _buildSection(
              title: '6. Service Availability',
              content: '''We strive to provide reliable service, but cannot guarantee:

• Uninterrupted access to the application
• Error-free operation at all times
• Immediate response to all requests
• Service during maintenance periods or emergencies

Collection schedules may be affected by weather conditions, holidays, or other circumstances beyond our control.''',
            ),

            _buildSection(
              title: '7. Data and Privacy',
              content: '''Your use of ValWaste is also governed by our Privacy Policy, which is incorporated into these terms by reference. By using the service, you consent to:

• Collection and use of your data as described in our Privacy Policy
• Location tracking for service delivery purposes
• Communication regarding collection services
• Data sharing with authorized city personnel as necessary''',
            ),

            _buildSection(
              title: '8. Intellectual Property',
              content: '''The ValWaste application and all related content are owned by the City Government of Valenzuela. You may not:

• Copy, modify, or distribute the application
• Reverse engineer or attempt to extract source code
• Use our trademarks or logos without permission
• Create derivative works based on our service

You retain ownership of any content you submit through the application.''',
            ),

            _buildSection(
              title: '9. Limitation of Liability',
              content: '''The City Government of Valenzuela shall not be liable for:

• Delays in waste collection due to circumstances beyond our control
• Damages resulting from service interruptions
• Loss of data or information
• Indirect, incidental, or consequential damages
• Actions of third-party service providers

Our liability is limited to the maximum extent permitted by law.''',
            ),

            _buildSection(
              title: '10. Modifications to Service',
              content: '''We reserve the right to:

• Modify or discontinue the service at any time
• Update these terms and conditions
• Change service features or functionality
• Implement new policies or procedures

We will provide reasonable notice of significant changes when possible.''',
            ),

            _buildSection(
              title: '11. Termination',
              content: '''We may terminate or suspend your access to ValWaste:

• For violation of these terms
• For misuse of the service
• For providing false information
• At our discretion with or without cause

You may terminate your account at any time by contacting us or deleting the application.''',
            ),

            _buildSection(
              title: '12. Governing Law',
              content: '''These terms are governed by the laws of the Republic of the Philippines and the ordinances of Valenzuela City. Any disputes shall be resolved in the appropriate courts of Valenzuela City.''',
            ),

            _buildSection(
              title: '13. Contact Information',
              content: '''For questions about these Terms and Conditions, please contact:

• City Government of Valenzuela
• Environmental Management Office
• Email: valwaste@valenzuela.gov.ph
• Phone: (02) 8292-3000
• Address: Valenzuela City Hall, Valenzuela City, Metro Manila

We will respond to inquiries within reasonable time frames.''',
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
