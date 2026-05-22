import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Color theme option
class ColorTheme {
  final String name;
  final Color color;
  final String hexCode;

  const ColorTheme({
    required this.name,
    required this.color,
    required this.hexCode,
  });
}

/// Add New Service Dialog
class AddNewServiceDialog extends StatefulWidget {
  const AddNewServiceDialog({super.key});

  @override
  State<AddNewServiceDialog> createState() => _AddNewServiceDialogState();
}

class _AddNewServiceDialogState extends State<AddNewServiceDialog> {
  final _nameController = TextEditingController();
  final List<String> _selectedDays = [];
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  String _selectedColor = 'Blue';

  final List<ColorTheme> _colorThemes = const [
    ColorTheme(name: 'Blue', color: Color(0xFF2563EB), hexCode: '#2563EB'),
    ColorTheme(name: 'Green', color: Color(0xFF22C55E), hexCode: '#22C55E'),
    ColorTheme(name: 'Purple', color: Color(0xFFA855F7), hexCode: '#A855F7'),
    ColorTheme(name: 'Pink', color: Color(0xFFEC4899), hexCode: '#EC4899'),
    ColorTheme(name: 'Cyan', color: Color(0xFF06B6D4), hexCode: '#06B6D4'),
    ColorTheme(name: 'Orange', color: Color(0xFFF97316), hexCode: '#F97316'),
  ];

  final List<String> _dayOptions = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening
          ? (_openingTime ?? const TimeOfDay(hour: 7, minute: 0))
          : (_closingTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${minute} $period';
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      _showErrorDialog('Please enter a service name');
      return;
    }

    if (_selectedDays.isEmpty) {
      _showErrorDialog('Please select at least one day');
      return;
    }

    if (_openingTime == null || _closingTime == null) {
      _showErrorDialog('Please set opening and closing times');
      return;
    }

    final selectedColorTheme = _colorThemes.firstWhere((c) => c.name == _selectedColor);

    Navigator.pop(context, {
      'name': _nameController.text.toUpperCase(),
      'color': selectedColorTheme.hexCode,
      'openingTime': '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}',
      'closingTime': '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}',
      'daysOpen': _selectedDays.join(','),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Service Name
            Text(
              'Service Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., CARDIOLOGY, NEUROLOGY',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.buttonPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),

            // Color Theme
            Text(
              'Color Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorThemes.map((colorTheme) {
                final isSelected = _selectedColor == colorTheme.name;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorTheme.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colorTheme.color : colorTheme.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: colorTheme.color, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      colorTheme.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : colorTheme.color,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Opening/Closing Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opening Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _openingTime != null ? _formatTime(_openingTime) : 'Select time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _openingTime != null ? Colors.grey[800] : Colors.grey[400],
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Closing Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _closingTime != null ? _formatTime(_closingTime) : 'Select time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _closingTime != null ? Colors.grey[800] : Colors.grey[400],
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Days Open
            Text(
              'Days Open',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dayOptions.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: Container(
                    width: 56,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.buttonPrimary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
