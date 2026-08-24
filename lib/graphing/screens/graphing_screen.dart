import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:math_expressions/math_expressions.dart';

class GraphingScreen extends StatefulWidget {
  const GraphingScreen({super.key});

  @override
  GraphingScreenState createState() => GraphingScreenState();
}

class GraphingScreenState extends State<GraphingScreen> {
  final TextEditingController _functionController = TextEditingController(text: 'x^2');
  List<FlSpot> _spots = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _generatePoints();
  }

  void _generatePoints() {
    setState(() {
      _spots.clear();
      _error = '';
    });

    final expStr = _functionController.text.trim();
    if (expStr.isEmpty) return;

    try {
      final GrammarParser p = GrammarParser();
      // Replace implied multiplication if needed, basic preprocessing
      String processed = expStr.replaceAllMapped(RegExp(r'(\d)x'), (match) => '${match.group(1)}*x');
      Expression exp = p.parse(processed);
      ContextModel cm = ContextModel();

      List<FlSpot> spots = [];
      for (double x = -10; x <= 10; x += 0.1) {
        cm.bindVariable(Variable('x'), Number(x));
        try {
          final evaluator = RealEvaluator(cm);
          double y = evaluator.evaluate(exp).toDouble();
          if (!y.isNaN && !y.isInfinite && y > -100 && y < 100) {
            spots.add(FlSpot(x, y));
          }
        } catch (e) {
          // ignore specific point error
        }
      }

      setState(() {
        _spots = spots;
      });
    } catch (e) {
      setState(() {
        _error = 'صيغة الدالة غير صحيحة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسم البياني'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('y = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _functionController,
                    decoration: InputDecoration(
                      hintText: 'مثال: sin(x) أو x^2',
                      errorText: _error.isEmpty ? null : _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _generatePoints(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _generatePoints,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _spots.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للرسم'))
                  : LineChart(
                      LineChartData(
                        clipData: FlClipData.all(),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        minX: -10,
                        maxX: 10,
                        minY: -20,
                        maxY: 20,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
