import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../calculator/controllers/calculator_provider.dart';

class VariablesManagerScreen extends StatefulWidget {
  const VariablesManagerScreen({super.key});

  @override
  VariablesManagerScreenState createState() => VariablesManagerScreenState();
}

class VariablesManagerScreenState extends State<VariablesManagerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  void _addVariable(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة متغير جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المتغير (مثال: x, a)'),
              ),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'القيمة (مثال: 3.14)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final value = double.tryParse(_valueController.text);
                if (name.isNotEmpty && value != null) {
                  context.read<CalculatorProvider>().setVariable(name, value);
                  _nameController.clear();
                  _valueController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final variables = provider.variables; // Need to expose variables in provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المتغيرات'),
        centerTitle: true,
      ),
      body: variables.isEmpty
          ? const Center(child: Text('لا توجد متغيرات محفوظة'))
          : ListView.builder(
              itemCount: variables.length,
              itemBuilder: (context, index) {
                final key = variables.keys.elementAt(index);
                final value = variables[key];
                return ListTile(
                  leading: CircleAvatar(child: Text(key)),
                  title: Text('$key = $value', style: const TextStyle(fontSize: 18)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      provider.removeVariable(key);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVariable(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
