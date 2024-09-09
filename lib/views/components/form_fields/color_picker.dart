import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

class EasyWalletColorPickerField extends StatelessWidget {
  final void Function(Color) onColorChanged;

  const EasyWalletColorPickerField({super.key, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: Text(Intl.message('pickAColor')),
        onPressed: () => _showColorPicker(context),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Intl.message('pickAColor')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Colors.black,
              onColorChanged: onColorChanged,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(Intl.message('done')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
