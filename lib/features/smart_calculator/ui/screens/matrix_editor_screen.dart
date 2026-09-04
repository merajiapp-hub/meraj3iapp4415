import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ml_linalg/matrix.dart';
import '../../../../theme/app_theme.dart';
import '../../engines/matrix_engine.dart';

class MatrixEditorScreen extends StatefulWidget {
  const MatrixEditorScreen({super.key});

  @override
  State<MatrixEditorScreen> createState() => _MatrixEditorScreenState();
}

class _MatrixEditorScreenState extends State<MatrixEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _rowsA = 2, _colsA = 2;
  int _rowsB = 2;
  late List<List<TextEditingController>> _ctrlA;
  late List<List<TextEditingController>> _ctrlB;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _initCtrlA();
    _initCtrlB();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (var row in _ctrlA) { for (var c in row) { c.dispose(); } }
    for (var row in _ctrlB) { for (var c in row) { c.dispose(); } }
    super.dispose();
  }

  void _initCtrlA() {
    _ctrlA = List.generate(_rowsA, (i) => List.generate(_colsA, (j) => TextEditingController(text: '0')));
  }
  void _initCtrlB() {
    _ctrlB = List.generate(_rowsB, (i) => List.generate(_rowsB, (j) => TextEditingController(text: '0')));
  }

  Matrix _buildMatrix(List<List<TextEditingController>> ctrl, int r, int c) {
    return Matrix.fromList(
      List.generate(r, (i) => List.generate(c, (j) => double.tryParse(ctrl[i][j].text) ?? 0.0)),
    );
  }

  void _op(String op) {
    try {
      final A = _buildMatrix(_ctrlA, _rowsA, _colsA);
      String res = '';
      switch (op) {
        case 'det':
          res = 'det(A) = ${MatrixEngine.determinant(A).toStringAsFixed(4)}';
          break;
        case 'inv':
          final inv = MatrixEngine.inverse(A);
          res = 'A⁻¹ =\n${_matrixToString(inv)}';
          break;
        case 'trans':
          res = 'Aᵀ =\n${_matrixToString(A.transpose())}';
          break;
        case 'rank':
          res = 'رتبة A = ${MatrixEngine.rank(A)}';
          break;
        case 'add':
          final B = _buildMatrix(_ctrlB, _rowsB, _rowsB);
          if (_rowsA != _rowsB || _colsA != _rowsB) { setState(() => _result = 'الأبعاد غير متوافقة'); return; }
          res = 'A + B =\n${_matrixToString((A + B))}';
          break;
        case 'sub':
          final B = _buildMatrix(_ctrlB, _rowsB, _rowsB);
          if (_rowsA != _rowsB || _colsA != _rowsB) { setState(() => _result = 'الأبعاد غير متوافقة'); return; }
          res = 'A - B =\n${_matrixToString((A - B))}';
          break;
        case 'mul':
          final B = _buildMatrix(_ctrlB, _rowsB, _rowsB);
          if (_colsA != _rowsB) { setState(() => _result = 'يجب أن يكون عدد أعمدة A = عدد صفوف B'); return; }
          res = 'A × B =\n${_matrixToString((A * B))}';
          break;
      }
      setState(() => _result = res);
    } catch (e) {
      setState(() => _result = 'خطأ: ${e.toString()}');
    }
  }

  String _matrixToString(Matrix m) {
    return m.rows.map((r) => '[ ${r.map((v) => v.toStringAsFixed(3)).join('  ')} ]').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [Tab(text: 'المصفوفة A'), Tab(text: 'المصفوفة B')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildMatrixEditor(context, _ctrlA, _rowsA, _colsA,
                  onRowChange: (v) => setState(() { _rowsA = v!; _initCtrlA(); _result = ''; }),
                  onColChange: (v) => setState(() { _colsA = v!; _initCtrlA(); _result = ''; })),
              _buildMatrixEditor(context, _ctrlB, _rowsB, _rowsB,
                  onRowChange: (v) => setState(() { _rowsB = v!; _initCtrlB(); _result = ''; }),
                  onColChange: null),
            ],
          ),
        ),
        _buildButtons(),
        if (_result.isNotEmpty) _buildResult(isDark),
      ],
    );
  }

  Widget _buildMatrixEditor(
    BuildContext context,
    List<List<TextEditingController>> ctrls, int rows, int cols, {
    required Function(int?)? onRowChange,
    required Function(int?)? onColChange,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('الصفوف:', style: GoogleFonts.tajawal()),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: rows,
                    isDense: true,
                    alignment: Alignment.center,
                    items: [2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e', style: GoogleFonts.tajawal()))).toList(),
                    onChanged: onRowChange,
                  ),
                ),
              ),
              if (onColChange != null) ...[
                const SizedBox(width: 24),
                Text('الأعمدة:', style: GoogleFonts.tajawal()),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: cols,
                      isDense: true,
                      alignment: Alignment.center,
                      items: [2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e', style: GoogleFonts.tajawal()))).toList(),
                      onChanged: onColChange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          for (int r = 0; r < rows; r++) ...[
            Row(
              children: [
                const Text('[', style: TextStyle(fontSize: 28, color: Colors.grey)),
                ...List.generate(cols, (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: ctrls[r][c],
                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                )),
                const Text(']', style: TextStyle(fontSize: 28, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _btn('det(A)', () => _op('det'), Colors.blue),
          _btn('A⁻¹', () => _op('inv'), Colors.orange),
          _btn('Aᵀ', () => _op('trans'), Colors.teal),
          _btn('رتبة A', () => _op('rank'), Colors.purple),
          _btn('A + B', () => _op('add'), Colors.green),
          _btn('A - B', () => _op('sub'), Colors.red),
          _btn('A × B', () => _op('mul'), Colors.indigo),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback fn, Color color) {
    return ElevatedButton(
      onPressed: fn,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResult(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _result,
        style: GoogleFonts.tajawal(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}


