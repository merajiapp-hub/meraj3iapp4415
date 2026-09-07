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
                  _buildSectionHeader('Outils principaux'),
                  _buildDrawerItem(
                    context,
                    Icons.calculate,
                    'Calculatrice',
                    () {},
                  ),
                  _buildDrawerItem(context, Icons.history, 'Historique', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  }),
                  _buildDrawerItem(context, Icons.superscript, 'Variables', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VariablesManagerScreen(),
                      ),
                    );
                  }),
                  _buildDrawerItem(
                    context,
                    Icons.swap_horiz,
                    "Convertisseur d'unites",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UnitConverterScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(context, Icons.code, 'Programmation', () {}),

                  const Divider(),
                  _buildSectionHeader('Mathematiques'),
                  _buildDrawerItem(context, Icons.show_chart, 'Graphique', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GraphingScreen()),
                    );
                  }),
                  _buildDrawerItem(
                    context,
                    Icons.functions,
                    'Formules mathematiques',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormulaLibraryScreen(
                            categoryName: 'Formules mathematiques',
                            categories: mathFormulas,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(context, Icons.grid_on, 'Matrices', () {}),

                  const Divider(),
                  _buildSectionHeader('Physique et chimie'),
                  _buildDrawerItem(
                    context,
                    Icons.flash_on,
                    'Formules de physique',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormulaLibraryScreen(
                            categoryName: 'Formules de physique',
                            categories: physicsFormulas,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(context, Icons.science, 'Chimie', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormulaLibraryScreen(
                          categoryName: 'Chimie',
                          categories: chemistryFormulas,
                        ),
                      ),
                    );
                  }),

                  const Divider(),
                  _buildDrawerItem(
                    context,
                    Icons.settings,
                    'Parametres',
                    () {},
                  ),
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

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
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
