import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  UnitConverterScreenState createState() => UnitConverterScreenState();
}

class UnitConverterScreenState extends State<UnitConverterScreen> {
  String _category = 'الطول';
  String _fromUnit = 'متر (m)';
  String _toUnit = 'كيلومتر (km)';
  double _inputValue = 1.0;

  final Map<String, List<String>> _units = {
    'الطول': ['متر (m)', 'كيلومتر (km)', 'سنتيمتر (cm)', 'ميل (mile)'],
    'الكتلة': ['جرام (g)', 'كيلوجرام (kg)', 'طن (ton)', 'باوند (lb)'],
    'درجة الحرارة': ['مئوي (C)', 'فهرنهايت (F)', 'كلفن (K)'],
  };

  double _convert() {
    if (_category == 'الطول') {
      double valueInMeters = _inputValue;
      if (_fromUnit == 'كيلومتر (km)') valueInMeters = _inputValue * 1000;
      if (_fromUnit == 'سنتيمتر (cm)') valueInMeters = _inputValue / 100;
      if (_fromUnit == 'ميل (mile)') valueInMeters = _inputValue * 1609.34;

      if (_toUnit == 'متر (m)') return valueInMeters;
      if (_toUnit == 'كيلومتر (km)') return valueInMeters / 1000;
      if (_toUnit == 'سنتيمتر (cm)') return valueInMeters * 100;
      if (_toUnit == 'ميل (mile)') return valueInMeters / 1609.34;
    }

    if (_category == 'الكتلة') {
      double valueInGrams = _inputValue;
      if (_fromUnit == 'كيلوجرام (kg)') valueInGrams = _inputValue * 1000;
      if (_fromUnit == 'طن (ton)') valueInGrams = _inputValue * 1000000;
      if (_fromUnit == 'باوند (lb)') valueInGrams = _inputValue * 453.592;

      if (_toUnit == 'جرام (g)') return valueInGrams;
      if (_toUnit == 'كيلوجرام (kg)') return valueInGrams / 1000;
      if (_toUnit == 'طن (ton)') return valueInGrams / 1000000;
      if (_toUnit == 'باوند (lb)') return valueInGrams / 453.592;
    }

    if (_category == 'درجة الحرارة') {
      double valueInCelsius = _inputValue;
      if (_fromUnit == 'فهرنهايت (F)') valueInCelsius = (_inputValue - 32) * 5 / 9;
      if (_fromUnit == 'كلفن (K)') valueInCelsius = _inputValue - 273.15;

      if (_toUnit == 'مئوي (C)') return valueInCelsius;
      if (_toUnit == 'فهرنهايت (F)') return (valueInCelsius * 9 / 5) + 32;
      if (_toUnit == 'كلفن (K)') return valueInCelsius + 273.15;
    }

    return _inputValue;
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محول الوحدات'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown(
              label: 'التصنيف',
              value: _category,
              items: _units.keys.toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _category = val;
                    _fromUnit = _units[val]!.first;
                    _toUnit = _units[val]!.last;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'القيمة', border: OutlineInputBorder()),
                    onChanged: (val) => setState(() => _inputValue = double.tryParse(val) ?? 0.0),
                    controller: TextEditingController(text: _inputValue == 1.0 ? '1' : _inputValue.toString()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'من',
                    value: _fromUnit,
                    items: _units[_category]!,
                    onChanged: (val) => setState(() => _fromUnit = val!),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Icon(Icons.arrow_downward, size: 32),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _convert().toStringAsFixed(4).replaceAll(RegExp(r"([.]*0+)(?!\d)"), ""),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'إلى',
                    value: _toUnit,
                    items: _units[_category]!,
                    onChanged: (val) => setState(() => _toUnit = val!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
