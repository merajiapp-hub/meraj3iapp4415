import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../managers/gemini_math_assistant.dart';
import '../../../../theme/app_theme.dart';

class EquationSolverScreen extends StatefulWidget {
  final String title;
  final String hintText;

  const EquationSolverScreen({
    super.key,
    this.title = 'المساعد الذكي (معادلات وتفاضل)',
    this.hintText = 'أدخل المعادلة هنا...',
  });

  @override
  State<EquationSolverScreen> createState() => _EquationSolverScreenState();
}

class _EquationSolverScreenState extends State<EquationSolverScreen> {
  String _input = '';
  String _solution = '';
  bool _isLoading = false;

  final ScrollController _scrollController = ScrollController();

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'AC') {
        _input = '';
        _solution = '';
      } else if (key == 'DEL') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else {
        _input += key;
      }
    });
  }

  Future<void> _solve() async {
    if (_input.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _solution = '';
    });

    try {
      final prompt = 'حل هذه المعادلة أو العملية الرياضية خطوة بخطوة باللغة العربية مع توضيح القاعدة المستخدمة: $_input';
      final res = await GeminiMathAssistant.askMathQuestion(prompt);
      setState(() {
        _solution = res;
      });
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _solution = 'حدث خطأ: لا يمكن الاتصال بالمساعد الذكي.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final surface = isDark ? AppTheme.surfaceDark : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textCol)),
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Display Area ──
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: _scrollController,
                children: [
                  // Input Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _input.isEmpty ? widget.hintText : _input,
                        textDirection: TextDirection.ltr,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          color: _input.isEmpty ? Colors.grey.withValues(alpha: 0.5) : textCol,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Solution Display
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: SpinKitThreeBounce(color: Colors.blueAccent, size: 30),
                    )
                  else if (_solution.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                'خطوات الحل:',
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          Text(
                            _solution,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              color: textCol.withValues(alpha: 0.9),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Math Keyboard ──
          _buildSmartKeyboard(isDark),
        ],
      ),
    );
  }

  Widget _buildSmartKeyboard(bool isDark) {
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    
    final rows = [
      ['x', 'y', '^', '√', 'AC', 'DEL'],
      ['(', ')', 'sin', 'cos', 'tan', '÷'],
      ['7', '8', '9', 'log', 'ln', '×'],
      ['4', '5', '6', '∫', 'd/dx', '-'],
      ['1', '2', '3', 'π', 'e', '+'],
      ['0', '.', '=', ',', 'lim', 'حل'],
    ];

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: Column(
        children: rows.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: _buildKey(key, isDark),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String label, bool isDark) {
    final isAction = label == 'حل';
    final isDelete = label == 'DEL' || label == 'AC';
    final isNumber = ['0','1','2','3','4','5','6','7','8','9','.'].contains(label);
    
    Color bgColor = isDark ? const Color(0xFF334155) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (isAction) {
      bgColor = Colors.blueAccent;
      textColor = Colors.white;
    } else if (isDelete) {
      bgColor = Colors.redAccent.withValues(alpha: 0.8);
      textColor = Colors.white;
    } else if (!isNumber) {
      bgColor = isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
      textColor = isDark ? Colors.amberAccent : Colors.deepOrange;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isAction) {
              _solve();
            } else {
              _onKeyPress(label);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isAction || isDelete ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: isAction ? 'Tajawal' : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
