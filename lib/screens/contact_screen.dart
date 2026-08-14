import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(
    String urlString, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: mode)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Exception while launching $urlString: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اتصل بنا',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildContactCard(
              context,
              'واتساب 1',
              '44 15 41 42',
              Icons.chat_bubble_outline_rounded,
              Colors.green,
              () => _launchUrl(
                'whatsapp://send?phone=+22244154142',
                mode: LaunchMode.externalNonBrowserApplication,
              ),
            ),
            _buildContactCard(
              context,
              'واتساب 2',
              '43 66 33 86',
              Icons.chat_bubble_outline_rounded,
              Colors.green,
              () => _launchUrl(
                'whatsapp://send?phone=+22243663386',
                mode: LaunchMode.externalNonBrowserApplication,
              ),
            ),
            _buildContactCard(
              context,
              'البريد الإلكتروني',
              'merajiapp@gmail.com',
              Icons.alternate_email_rounded,
              Colors.redAccent,
              () => _launchUrl(
                'mailto:merajiapp@gmail.com',
                mode: LaunchMode.externalApplication,
              ),
            ),
            _buildContactCard(
              context,
              'فيسبوك',
              'صفحتنا الرسمية',
              Icons.facebook_rounded,
              const Color(0xFF1877F2),
              () =>
                  _launchUrl(
                    'fb://page/meraj3i',
                    mode: LaunchMode.externalNonBrowserApplication,
                  ).catchError(
                    (_) => _launchUrl(
                      'https://facebook.com/meraj3i',
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 64,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'نحن هنا لمساعدتك',
          style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'تواصل معنا عبر القنوات التالية وسنرد عليك في أسرع وقت ممكن',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
