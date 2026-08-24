import 'package:flutter/material.dart';
import '../../calculator/screens/scientific_calculator_screen.dart';

class FormulaCategory {
  final String title;
  final IconData icon;
  final List<Formula> formulas;

  FormulaCategory({required this.title, required this.icon, required this.formulas});
}

class Formula {
  final String name;
  final String mathExpression;
  final String description;

  Formula({required this.name, required this.mathExpression, required this.description});
}

class FormulaLibraryScreen extends StatelessWidget {
  final String categoryName;
  final List<FormulaCategory> categories;

  const FormulaLibraryScreen({super.key, required this.categoryName, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName), centerTitle: true),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ExpansionTile(
            leading: Icon(cat.icon, color: Theme.of(context).colorScheme.primary),
            title: Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: cat.formulas.map((f) => ListTile(
              title: Text(f.name),
              subtitle: Text(f.description),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.mathExpression,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              onTap: () {
                // Here we can navigate back to calculator and pre-fill the expression
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScientificCalculatorScreen()));
              },
            )).toList(),
          );
        },
      ),
    );
  }
}

// Sample Data
final List<FormulaCategory> physicsFormulas = [
  FormulaCategory(
    title: 'الحركة والسرعة',
    icon: Icons.speed,
    formulas: [
      Formula(name: 'السرعة المتجهة', mathExpression: 'v = d/t', description: 'السرعة تساوي المسافة على الزمن'),
      Formula(name: 'التسارع', mathExpression: 'a = (v-u)/t', description: 'التسارع يساوي التغير في السرعة على الزمن'),
    ]
  ),
  FormulaCategory(
    title: 'القوة والطاقة',
    icon: Icons.bolt,
    formulas: [
      Formula(name: 'قانون نيوتن الثاني', mathExpression: 'F = m*a', description: 'القوة تساوي الكتلة في التسارع'),
      Formula(name: 'الطاقة الحركية', mathExpression: 'KE = 0.5*m*v^2', description: 'نصف الكتلة في مربع السرعة'),
    ]
  )
];

final List<FormulaCategory> chemistryFormulas = [
  FormulaCategory(
    title: 'الغازات',
    icon: Icons.science,
    formulas: [
      Formula(name: 'قانون الغاز المثالي', mathExpression: 'P*V = n*R*T', description: 'الضغط في الحجم يساوي المولات في الثابت في الحرارة'),
    ]
  ),
  FormulaCategory(
    title: 'المحاليل',
    icon: Icons.water_drop,
    formulas: [
      Formula(name: 'التركيز المولي', mathExpression: 'C = n/V', description: 'المولات مقسومة على الحجم'),
    ]
  )
];

final List<FormulaCategory> mathFormulas = [
  FormulaCategory(
    title: 'الجبر',
    icon: Icons.functions,
    formulas: [
      Formula(name: 'المعادلة التربيعية', mathExpression: '(-b±√(b²-4ac))/2a', description: 'حل معادلة من الدرجة الثانية'),
    ]
  ),
  FormulaCategory(
    title: 'الهندسة',
    icon: Icons.category,
    formulas: [
      Formula(name: 'مساحة الدائرة', mathExpression: 'A = π*r^2', description: 'مساحة دائرة بنصف قطر r'),
      Formula(name: 'نظرية فيثاغورس', mathExpression: 'c^2 = a^2 + b^2', description: 'في المثلث القائم'),
    ]
  )
];
