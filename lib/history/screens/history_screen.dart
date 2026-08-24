import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calculator/controllers/calculator_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final history = provider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              provider.clearHistory();
            },
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('لا توجد عمليات سابقة'))
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  title: Text(item['expression'] ?? '', style: const TextStyle(fontSize: 18)),
                  subtitle: Text(
                    '= ${item['result']}',
                    style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    provider.useHistoryItem(item['expression'] ?? '');
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
