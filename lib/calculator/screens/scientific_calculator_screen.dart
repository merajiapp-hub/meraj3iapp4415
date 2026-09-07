import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calculator_provider.dart';
import '../widgets/display_screen.dart';
import '../widgets/keypad_grid.dart';
import '../theme/calculator_theme.dart';
import '../../shared/widgets/calculator_drawer.dart';
import '../../history/screens/history_screen.dart';

class ScientificCalculatorScreen extends StatelessWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the state for this screen
    return ChangeNotifierProvider(
      create: (_) => CalculatorProvider(),
      child: Consumer<CalculatorProvider>(
        builder: (context, provider, child) {
          final theme = CalculatorTheme.getTheme(provider.themeStyle);
          return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: AppBar(
              title: const Text('Calculatrice'),
              centerTitle: true,
              backgroundColor: theme.backgroundColor,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.operatorTextColor),
              titleTextStyle: TextStyle(
                color: theme.operatorTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _showThemePicker(context, provider);
                  },
                ),
              ],
            ),
            drawer: const CalculatorDrawer(),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: const [
                    Expanded(flex: 3, child: CalculatorDisplay()),
                    SizedBox(height: 16),
                    Expanded(flex: 7, child: CalculatorKeypad()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showThemePicker(BuildContext context, CalculatorProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paramètres',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Sombre moderne'),
                onTap: () {
                  provider.setThemeStyle(CalculatorThemeStyle.modernDark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Classique clair'),
                onTap: () {
                  provider.setThemeStyle(CalculatorThemeStyle.classicLight);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Neon professionnel'),
                onTap: () {
                  provider.setThemeStyle(CalculatorThemeStyle.neonPro);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
