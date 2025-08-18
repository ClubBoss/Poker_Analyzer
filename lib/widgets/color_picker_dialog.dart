import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../helpers/color_utils.dart';

Future<Color?> showColorPickerDialog(
  BuildContext context, {
  Color? initialColor,
}) {
  Color color = initialColor ?? Colors.blue;
  final controller = TextEditingController(text: colorToHex(color));
  return showDialog<Color>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: color,
              onColorChanged: (c) {
                color = c;
                controller.text = colorToHex(c);
                setState(() {});
              },
              enableAlpha: false,
              displayThumbColor: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(prefixText: '#'),
              onChanged: (v) {
                final hex = v.startsWith('#') ? v : '#$v';
                if (RegExp(r'^#[0-9A-Fa-f]{6}\$').hasMatch(hex)) {
                  color = colorFromHex(hex);
                  setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, color),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
