import 'package:flutter/material.dart';

class CheckboxGroupWidget extends StatefulWidget {
  final List<String> labels;
  final List<String> value;
  final Function(List<String>) onChanged;

  CheckboxGroupWidget({required this.labels,required this.value, required this.onChanged});

  @override
  _CheckboxGroupWidgetState createState() => _CheckboxGroupWidgetState();
}

class _CheckboxGroupWidgetState extends State<CheckboxGroupWidget> {
  Map<String, bool> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    for (var value in widget.value) {
      _selectedValues[value] = !widget.value.contains(value);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.labels.asMap().entries.map((entry) {
        int index = entry.key;
        String label = entry.value;
        String value = widget.value[index];
        return CheckboxListTile(
          title: Text(label),
          value: _selectedValues[value],
          checkColor: Colors.white,
          activeColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onChanged: (bool? isSelected) {
            setState(() {
              _selectedValues[value] = isSelected!;
              widget.onChanged(
                _selectedValues.entries
                    .where((entry) => entry.value)
                    .map((entry) => entry.key)
                    .toList(),
              );
            });
          },
        );
      }).toList(),
    );
  }
}