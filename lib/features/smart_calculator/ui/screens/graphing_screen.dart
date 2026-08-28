import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../engines/graph_engine.dart';
import '../../../../theme/app_theme.dart';

class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  State<GraphingScreen> createState() => _GraphingScreenState();
}

class _GraphingScreenState extends State<GraphingScreen> {
  String _input = 'x^2';
  List<GraphPoint> _points = [];
  String _error = '';
  
  // Viewport bounds
  final double _minX = -10;
  final double _maxX = 10;
  double _minY = -10;
  double _maxY = 10;

  @override
  void initState() {
    super.initState();
    _plotGraph();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'AC') {
        _input = '';
      } else if (key == 'DEL') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else {
        _input += key;
      }
    });
  }

  void _plotGraph() {
    setState(() => _error = '');
    if (_input.trim().isEmpty) return;

    try {
      final points = GraphEngine.generatePoints(
        _input,
        minX: _minX,
        maxX: _maxX,
        steps: 300,
      );
      
      // Calculate dynamic Y bounds
      double minY = double.infinity;
      double maxY = double.negativeInfinity;
      for (var p in points) {
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      
      // Add padding to Y bounds
      if (points.isNotEmpty && minY != double.infinity) {
        double padding = (maxY - minY) * 0.1;
        if (padding == 0) padding = 1;
        _minY = (minY - padding).clamp(-100, 100);
        _maxY = (maxY + padding).clamp(-100, 100);
      }

      setState(() => _points = points);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final surface = isDark ? AppTheme.surfaceDark : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;
    final accent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          'الرسم البياني الذكي',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Chart Area ──
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: _points.isEmpty && _error.isEmpty
                  ? _buildEmptyState(textCol)
                  : (_error.isNotEmpty ? _buildErrorState() : _buildChart(textCol, accent)),
            ),
          ),

          // ── Input Display ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Text(
                  'f(x) = ',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _input.isEmpty ? '_' : _input,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 26,
                        color: _input.isEmpty ? Colors.grey : textCol,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Math Keyboard ──
          Expanded(
            flex: 5,
            child: _buildSmartKeyboard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textCol) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, size: 60, color: textCol.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'أدخل دالة لرسمها',
            style: GoogleFonts.tajawal(color: textCol.withValues(alpha: 0.5), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        _error,
        textAlign: TextAlign.center,
        style: GoogleFonts.tajawal(color: Colors.redAccent, fontSize: 16),
      ),
    );
  }

  Widget _buildChart(Color textCol, Color accent) {
    return LineChart(
      LineChartData(
        minX: _minX,
        maxX: _maxX,
        minY: _minY,
        maxY: _maxY,
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (_) => FlLine(color: textCol.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: textCol.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(color: textCol.withValues(alpha: 0.5), fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(color: textCol.withValues(alpha: 0.5), fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: textCol.withValues(alpha: 0.2)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _points.map((p) => FlSpot(p.x, p.y)).toList(),
            isCurved: true,
            color: accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: accent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartKeyboard(bool isDark) {
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    
    final rows = [
      ['x', '^', '√', '(', ')', 'AC', 'DEL'],
      ['sin', 'cos', 'tan', '7', '8', '9', '÷'],
      ['asin', 'acos', 'atan', '4', '5', '6', '×'],
      ['log', 'ln', 'e', '1', '2', '3', '-'],
      ['π', 'abs', '.', '0', ',', '=', '+'],
    ];

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) {
                // Determine flexibility for special keys
                int flex = (key == 'رسم' || key == 'AC' || key == 'DEL') ? 2 : 1;
                if (row.last == key && key == '+') flex = 1; // standard
                
                return Expanded(
                  flex: flex,
                  child: _buildKey(key, isDark),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String label, bool isDark) {
    final isAction = label == '=';
    final isDelete = label == 'DEL' || label == 'AC';
    final isNumber = ['0','1','2','3','4','5','6','7','8','9','.'].contains(label);
    
    Color bgColor = isDark ? const Color(0xFF334155) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (isAction) {
      bgColor = const Color(0xFF10B981); // Green for Graph
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
              _plotGraph();
            } else {
              _onKeyPress(label);
            }
          },
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label == '=' ? 'رسم' : label,
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
