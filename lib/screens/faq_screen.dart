import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, dynamic>> _sections = [
    {
      'title': 'عام',
      'icon': Icons.help_outline_rounded,
      'color': Color(0xFF0EA5E9),
      'faqs': [
        {
          'q': 'هل التطبيق مجاني؟',
          'a':
              'نعم! تطبيق MERAJ3I مجاني بالكامل. يمكنك الوصول إلى جميع الكتب والمواد التعليمية دون أي رسوم.',
        },
        {
          'q': 'ما هي ميزة MERAJ3I AI؟',
          'a':
              'ميزة MERAJ3I AI هي مساعد ذكاء اصطناعي مدمج يساعدك في الإجابة عن الأسئلة الدراسية وفهم الدروس بطريقة تفاعلية.',
        },
        {
          'q': 'ما المراحل الدراسية المتاحة؟',
          'a':
              'يغطي التطبيق المرحلة الابتدائية (1-6)، الإعدادية (1-4)، والثانوية بجميع شعبها (علوم، رياضيات، آداب عصرية، آداب أصلية).',
        },
      ],
    },
    {
      'title': 'الاستخدام بدون إنترنت',
      'icon': Icons.wifi_off_rounded,
      'color': Color(0xFF10B981),
      'faqs': [
        {
          'q': 'هل يمكن استخدام التطبيق بدون إنترنت؟',
          'a':
              'نعم! بعد تنزيل الكتب داخل التطبيق يمكن قراءتها في أي وقت دون الحاجة لاتصال إنترنت. الكتب المحملة تظهر في صفحة "التنزيلات".',
        },
        {
          'q': 'كيف أحمّل كتاباً للقراءة دون إنترنت؟',
          'a':
              'عند فتح أي كتاب، اضغط على أيقونة التحميل ⬇ في شريط الأدوات العلوي. سيُحفظ الكتاب تلقائياً في جهازك.',
        },
      ],
    },
    {
      'title': 'الحساب الشخصي',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF8B5CF6),
      'faqs': [
        {
          'q': 'هل يمكن تغيير صورة الحساب؟',
          'a':
              'نعم، يمكن تغيير صورة الحساب في أي وقت من صفحة "الملف الشخصي". يمكنك اختيار صورة من المعرض أو التقاطها مباشرة.',
        },
        {
          'q': 'هل يمكنني تسجيل الدخول كضيف؟',
          'a':
              'نعم، يمكنك تصفح التطبيق كضيف دون إنشاء حساب. بعض الميزات مثل المفضلة وتتبع التقدم تتطلب تسجيل الدخول.',
        },
        {
          'q': 'هل يمكنني استخدام بصمة الإصبع لتأمين التطبيق؟',
          'a':
              'نعم! يوفر التطبيق ميزة التحقق البيومتري (بصمة أو وجه). يمكن تفعيلها من الإعدادات > الأمان.',
        },
      ],
    },
    {
      'title': 'الدعم والتواصل',
      'icon': Icons.support_agent_rounded,
      'color': Color(0xFFEF4444),
      'faqs': [
        {
          'q': 'كيف أتواصل مع الدعم؟',
          'a':
              'يمكنك التواصل عبر البريد الإلكتروني: merajiapp@gmail.com وسيتم الرد خلال 24-48 ساعة.',
        },
        {
          'q': 'كيف أبلّغ عن خطأ في التطبيق؟',
          'a':
              'أرسل لنا بريدًا على merajiapp@gmail.com يصف المشكلة مع اسم الجهاز ونسخة التطبيق. شكرًا لمساعدتك!',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'الأسئلة الشائعة',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.quiz_rounded,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, sIndex) {
                final section = _sections[sIndex];
                final faqs = section['faqs'] as List<Map<String, String>>;
                final color = section['color'] as Color;
                final icon = section['icon'] as IconData;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sIndex > 0) const SizedBox(height: 8),
                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            section['title'] as String,
                            style: GoogleFonts.tajawal(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // FAQ Items
                    ...faqs.map(
                      (faq) => _FaqItem(
                        question: faq['q']!,
                        answer: faq['a']!,
                        accentColor: color,
                      ),
                    ),
                  ],
                );
              }, childCount: _sections.length),
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final Color accentColor;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.accentColor,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: _isExpanded
              ? widget.accentColor.withValues(alpha: 0.3)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _toggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Q',
                        style: GoogleFonts.outfit(
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(
                      begin: 0,
                      end: 0.5,
                    ).animate(_expandAnim),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.accentColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                child: Text(
                  widget.answer,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    height: 1.7,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
