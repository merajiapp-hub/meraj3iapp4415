import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم النسخ: $text', style: GoogleFonts.tajawal()),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              title: 'واتساب 1',
              // رقم بالاتجاه الصحيح LTR
              phoneNumber: '44154142',
              displayNumber: '44 15 41 42',
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.green,
              onCall: () => _launchUrl(
                'tel:+22244154142',
                mode: LaunchMode.externalApplication,
              ),
              onWhatsApp: () => _launchUrl(
                'whatsapp://send?phone=+22244154142',
                mode: LaunchMode.externalNonBrowserApplication,
              ),
            ),
            _buildContactCard(
              context,
              title: 'واتساب 2',
              phoneNumber: '43663386',
              displayNumber: '43 66 33 86',
              icon: Icons.chat_bubble_outline_rounded,
              color: Colors.green,
              onCall: () => _launchUrl(
                'tel:+22243663386',
                mode: LaunchMode.externalApplication,
              ),
              onWhatsApp: () => _launchUrl(
                'whatsapp://send?phone=+22243663386',
                mode: LaunchMode.externalNonBrowserApplication,
              ),
            ),
            _buildEmailCard(
              context,
              email: 'merajiapp@gmail.com',
              icon: Icons.alternate_email_rounded,
              color: Colors.redAccent,
              onTap: () => _launchUrl(
                'mailto:merajiapp@gmail.com',
                mode: LaunchMode.externalApplication,
              ),
            ),
            _buildFacebookCard(
              context,
              icon: Icons.facebook_rounded,
              color: const Color(0xFF1877F2),
              onTap: () => _launchUrl(
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
    BuildContext context, {
    required String title,
    required String phoneNumber,
    required String displayNumber,
    required IconData icon,
    required Color color,
    required VoidCallback onCall,
    required VoidCallback onWhatsApp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // رقم الهاتف بالاتجاه LTR دائماً لمنع العكس
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(
                          displayNumber,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // زر النسخ
                IconButton(
                  onPressed: () => _copyToClipboard(context, phoneNumber),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'نسخ الرقم',
                  color: Colors.grey[500],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text('اتصال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: Text('واتساب', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard(
    BuildContext context, {
    required String email,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البريد الإلكتروني',
                      style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    // البريد الإلكتروني دائماً LTR
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SelectableText(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, email),
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فيسبوك',
                      style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'صفحتنا الرسمية',
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
