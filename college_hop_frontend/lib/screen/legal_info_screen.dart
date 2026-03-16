import 'package:flutter/material.dart';
import 'package:college_hop/theme/app_scaffold.dart';


class LegalInformationScreen extends StatelessWidget {
  const LegalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: AppScaffold( // Assuming AppScaffold provides your gradient
        body: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Legal Information",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48)
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// TAB BAR (Updated for Gradient Transparency)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4), // Padding around the indicator
                decoration: BoxDecoration(
                  // We use a semi-transparent overlay instead of solid surface
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: TabBar(
                  // Remove the default bottom line
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(text: "Terms of Service"),
                    Tab(text: "Privacy Policy"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// TAB CONTENT
              const Expanded(
                child: TabBarView(
                  children: [
                    TermsOfServiceTab(),
                    PrivacyPolicyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// TERMS OF SERVICE
////////////////////////////////////////////////////////////

class TermsOfServiceTab extends StatelessWidget {
  const TermsOfServiceTab({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        _section(
          theme,
          "1. Introduction",
          "Welcome to College Hop! By accessing or using our platform, you agree to be bound by these Terms of Service. Please read them carefully.\nCollege Hop is a student networking platform designed to help students connect with each other for events, travel, and social activities.",
        ),

        _section(
          theme,
          "2. Eligibility",
          "•You must be at least 18 years old or have parental consent to use College Hop.\n•You must be a current student at an accredited educational institution or recent graduate.\n•You must provide accurate and complete information during registration.\n•You are responsible for maintaining the security of your account credentials.",
        ),

        _section(
          theme,
          "3. User Conduct",
          "You agree not to:\n•Use the platform for any illegal or unauthorized purpose\n•Harass, abuse, or harm other users\n•Post false, misleading, or fraudulent content\n•Attempt to gain unauthorized access to our systems\n•Use the platform for commercial purposes without permission",
        ),

        _section(
          theme,
          "4. Content Ownership",
          "You retain ownership of any content you post on College Hop. However, by posting content, you grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content on the platform.\nWe reserve the right to remove any content that violates these Terms or is otherwise objectionable.",
        ),

        _section(
          theme,
          "5. Limitation of Liability",
          "College Hop is provided as is without warranties of any kind. We are not liable for any damages arising from your use of the platform, including but not limited to travel arrangements, event attendance, or interactions with other users.",
        ),
        const SizedBox(height: 6),
        Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: .15),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Text(
        "Questions about our Terms?",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 6),

      Row(
        children: [
          Text(
            "Contact us at ",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),

          Text(
            "legal@collegehop.com",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ],
  ),
)
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// PRIVACY POLICY
////////////////////////////////////////////////////////////

class PrivacyPolicyTab extends StatelessWidget {
  const PrivacyPolicyTab({super.key});

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        _section(
          theme,
          "1. Introduction",
          "At College Hop, we take your privacy seriously. This Privacy Policy explains how we collect, use, and protect your personal information when you use our platform.",

        ),

        _section(
          theme,
          "2. Information We Collect",
          "We collect the following types of information:\n• Account Information: Name, email address, university, major, year of study\n• Profile Information: Bio, interests, location, profile photos\n• Verification Documents: Student ID for identity verification\n• Usage Data: Events attended, matches made, messages sent.",
        ),

        _section(
          theme,
          "3. How We Use Your Information",
          "We use your information to:\n• Provide and improve our services\n• Match you with other students based on shared interests and events\n• Send you notifications about matches, messages, and events\n• Verify your student status and maintain platform security\n• Analyze usage patterns to enhance user experience",
        ),

        _section(
          theme,
          "4. Information Sharing",
          "We do not sell your personal information to third parties. We may share your information only in the following circumstances:\n• With other users as part of the platform's functionality (profile information, matches)\n• With service providers who help us operate the platform\n• When required by law or to protect our rights",
        ),

        _section(
          theme,
          "5. Data Security",
          "We implement industry-standard security measures to protect your data, including encryption, secure servers, and regular security audits. However, no method of transmission over the internet is 100% secure.",
        ),

        _section(
          theme,
          "6. Your Rights",
          "You have the right to:\n• Access and update your personal information\n• Delete your account and associated data\n• Control your privacy settings and profile visibility\n• Opt out of marketing communication.",
        ),
        const SizedBox(height: 6),
        Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: .15),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      Text(
        "Privacy Questions or Concerns?",
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 6),

      Row(
        children: [
          Text(
            "Contact us at ",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),

          Text(
            "privacy@collegehop.com",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ],
  ),
)

      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// LEGAL SECTION CARD
////////////////////////////////////////////////////////////

Widget _section(ThemeData theme, String title, String content) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: .15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// TITLE (UNCHANGED COLOR)
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 6),

        /// CONTENT (CUSTOM COLOR)
        Text(
          content,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
