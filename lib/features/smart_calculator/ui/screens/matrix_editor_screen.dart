import 'package:flutter/material.dart';
import 'package:ml_linalg/matrix.dart';
import '../../engines/matrix_engine.dart';

class MatrixEditorScreen extends StatefulWidget {
  const MatrixEditorScreen({super.key});

  @override
  State<MatrixEditorScreen> createState() => _MatrixEditorScreenState();
}

class _MatrixEditorScreenState extends State<MatrixEditorScreen> {
  int _rows = 2;
  int _cols = 2;
  late List<List<TextEditingController>> _controllers;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      _rows,
      (i) => List.generate(_cols, (j) => TextEditingController(text: '0')),
    );
  }

  Matrix _buildMatrix() {
    List<List<double>> source = [];
    for (int i = 0; i < _rows; i++) {
      List<double> row = [];
      for (int j = 0; j < _cols; j++) {
        row.add(double.tryParse(_controllers[i][j].text) ?? 0);
      }
      source.add(row);
    }
    return Matrix.fromList(source);
  }

  void _calculateDeterminant() {
    try {
      Matrix a = _buildMatrix();
      double det = MatrixEngine.determinant(a);
      setState(() {
        _result = 'المحدد = $det';
      });
    } catch (e) {
       setState(() {
        _result = 'خطأ: ${e.toString()}';
      });
    }
  }

  void _calculateInverse() {
    try {
      Matrix a = _buildMatrix();
      Matrix inv = MatrixEngine.inverse(a);
      setState(() {
        _result = 'المعكوس:\n$inv';
      });
    } catch (e) {
       setState(() {
        _result = 'خطأ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المصفوفات', style: TextStyle(fontFamily: 'Tajawal')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('الصفوف: '),
                DropdownButton<int>(
                  value: _rows,
                  items: [2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() { _rows = v; _initControllers(); _result = '';});
                  },
                ),
                const SizedBox(width: 24),
                const Text('الأعمدة: '),
                DropdownButton<int>(
                  value: _cols,
                  items: [2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() { _cols = v; _initControllers(); _result = '';});
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _rows * _cols,
                itemBuilder: (context, index) {
                  int r = index ~/ _cols;
                  int c = index % _cols;
                  return TextField(
                    controller: _controllers[r][c],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _calculateDeterminant, child: const Text('المحدد')),
                ElevatedButton(onPressed: _calculateInverse, child: const Text('المعكوس')),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                _result,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
