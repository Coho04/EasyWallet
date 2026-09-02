import 'package:flutter/cupertino.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';

/// Asks the user for a colour in a Cupertino modal popup, the same shape the
/// settings view uses for its pickers. Returns null when nothing was picked.
///
/// This used to be a Material AlertDialog duplicated in the category index and
/// detail views, which looked foreign in this Cupertino-only app.
Future<Color?> showColorPickerSheet(
  BuildContext context,
  Color currentColor,
) async {
  Color? pickedColor;

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 420,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  Intl.message('pickAColor'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: (Color color) => pickedColor = color,
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Intl.message('done')),
              ),
            ],
          ),
        ),
      );
    },
  );

  return pickedColor;
}
