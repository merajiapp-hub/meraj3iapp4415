import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversionsScreen extends StatefulWidget {
  const ConversionsScreen({super.key});

  @override
  State<ConversionsScreen> createState() => _ConversionsScreenState();
}

class _ConversionsScreenState extends State<ConversionsScreen> {
  String _selectedCategory = 'الطول';
  String _fromUnit = 'm';
  String _toUnit = 'cm';
  double _inputValue = 1.0;
  
  final Map<String, Map<String, double>> _conversionRates = {
    'الطول': {
      'mm': 0.001,
      'cm': 0.01,
      'm': 1.0,
      'km': 1000.0,
      'inch': 0.0254,
      'ft': 0.3048,
      'yard': 0.9144,
      'mile': 1609.34,
    },
    'الوزن': {
      'mg': 0.000001,
      'g': 0.001,
      'kg': 1.0,
      'ton': 1000.0,
      'oz': 0.0283495,
      'lb': 0.453592,
    },
    'الزمن': {
      'second': 1.0,
      'minute': 60.0,
      'hour': 3600.0,
      'day': 86400.0,
      'week': 604800.0,
    },
    'المساحة': {
      'cm²': 0.0001,
      'm²': 1.0,
      'km²': 1000000.0,
      'acre': 4046.86,
      'hectare': 10000.0,
    },
    'الحجم': {
      'ml': 0.001,
      'liter': 1.0,
      'm³': 1000.0,
      'gallon': 3.78541,
    },
    'السرعة': {
      'm/s': 1.0,
      'km/h': 0.277778,
      'mph': 0.44704,
    },
    'البيانات': {
      'bit': 0.125,
      'byte': 1.0,
      'KB': 1024.0,
      'MB': 1048576.0,
      'GB': 1073741824.0,
      'TB': 1099511627776.0,
    }
  };

  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedCategory = newCategory;
        _fromUnit = _conversionRates[newCategory]!.keys.first;
        _toUnit = _conversionRates[newCategory]!.keys.elementAt(1);
      });
    }
  }

  double _convert() {
    if (_selectedCategory == 'الحرارة') {
       if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') return (_inputValue * 9/5) + 32;
       if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') return (_inputValue - 32) * 5/9;
       if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') return _inputValue + 273.15;
       if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') return _inputValue - 273.15;
       return _inputValue;
    }

    final fromRate = _conversionRates[_selectedCategory]![_fromUnit]!;
    final toRate = _conversionRates[_selectedCategory]![_toUnit]!;
    
    // Convert to base unit, then to target unit
    final baseValue = _inputValue * fromRate;
    return baseValue / toRate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _convert();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: _conversionRates.keys.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.tajawal()));
            }).toList(),
            onChanged: _onCategoryChanged,
            decoration: InputDecoration(
              labelText: 'الفئة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'القيمة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _inputValue = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButton<String>(value: _fromUnit,
                  items: _conversionRates[_selectedCategory]!.keys.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.tajawal()));
                  }).toList(),
                  onChanged: (val) => setState(() => _fromUnit = val!),
                  isExpanded: true,),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Icon(Icons.arrow_downward_rounded, size: 32, color: Colors.grey),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),
                    style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButton<String>(value: _toUnit,
                  items: _conversionRates[_selectedCategory]!.keys.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.tajawal()));
                  }).toList(),
                  onChanged: (val) => setState(() => _toUnit = val!),
                  isExpanded: true,),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


