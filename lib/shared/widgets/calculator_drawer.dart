import 'package:flutter/material.dart';
import '../../converter/screens/unit_converter_screen.dart';
import '../../variables/screens/variables_manager_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../graphing/screens/graphing_screen.dart';
import '../../formulas/screens/formula_library_screen.dart';

class CalculatorDrawer extends StatelessWidget {
  const CalculatorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'MERAJ3I Calc Pro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionHeader('الأدوات الأساسية'),
                  _buildDrawerItem(context, Icons.calculate, 'الحاسبة العلمية', () {}),
                  _buildDrawerItem(context, Icons.history, 'سجل الحاسبة', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  }),
                  _buildDrawerItem(context, Icons.superscript, 'قيمة متغيرة (Variables)', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VariablesManagerScreen()));
                  }),
                  _buildDrawerItem(context, Icons.swap_horiz, 'محول الوحدات', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitConverterScreen()));
                  }),
                  _buildDrawerItem(context, Icons.code, 'البرمجة', () {}),
                  
                  const Divider(),
                  _buildSectionHeader('الرياضيات'),
                  _buildDrawerItem(context, Icons.show_chart, 'الرسم البياني', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GraphingScreen()));
                  }),
                  _buildDrawerItem(context, Icons.functions, 'الصيغ الرياضية', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FormulaLibraryScreen(categoryName: 'الصيغ الرياضية', categories: mathFormulas)));
                  }),
                  _buildDrawerItem(context, Icons.grid_on, 'المصفوفات', () {}),
                  
                  const Divider(),
                  _buildSectionHeader('الفيزياء والكيمياء'),
                  _buildDrawerItem(context, Icons.flash_on, 'الصيغ الفيزيائية', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FormulaLibraryScreen(categoryName: 'الصيغ الفيزيائية', categories: physicsFormulas)));
                  }),
                  _buildDrawerItem(context, Icons.science, 'الكيمياء', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FormulaLibraryScreen(categoryName: 'الكيمياء', categories: chemistryFormulas)));
                  }),
                  
                  const Divider(),
                  _buildDrawerItem(context, Icons.settings, 'الإعدادات', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }
}
