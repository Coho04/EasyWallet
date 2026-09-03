import 'package:flutter/cupertino.dart';

/// One row of a settings list, in the shape iOS uses: a label on the left, the
/// value or control on the right, and the whole row as the tap target.
///
/// The label is set at a fixed size on purpose. The rest of the app uses
/// AutoText, which shrinks each string until it fits and therefore gives
/// neighbouring rows different type sizes.
class SettingsRow extends StatelessWidget {
  /// A row carrying a switch. Only the switch itself toggles.
  const SettingsRow.toggle({
    super.key,
    required this.label,
    required bool value,
    required ValueChanged<bool> onChanged,
  })  : _toggleValue = value,
        _onChanged = onChanged,
        value = null,
        onTap = null,
        _kind = _RowKind.toggle;

  /// A row showing a value and opening something when tapped.
  const SettingsRow.value({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  })  : _toggleValue = null,
        _onChanged = null,
        _kind = _RowKind.value;

  /// A row leading out of the app, to a web page.
  const SettingsRow.link({
    super.key,
    required this.label,
    required this.onTap,
  })  : value = null,
        _toggleValue = null,
        _onChanged = null,
        _kind = _RowKind.link;

  /// A row that only states something, such as the app version.
  const SettingsRow.info({
    super.key,
    required this.label,
    required this.value,
  })  : onTap = null,
        _toggleValue = null,
        _onChanged = null,
        _kind = _RowKind.info;

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool? _toggleValue;
  final ValueChanged<bool>? _onChanged;
  final _RowKind _kind;

  /// Apple's minimum comfortable tap target.
  static const double _minHeight = 44;
  static const double _labelSize = 16;

  @override
  Widget build(BuildContext context) {
    // No vertical padding: the minimum height below already guarantees a
    // comfortable target, and adding both makes the rows needlessly tall.
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: _labelSize,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            ..._trailing(context),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return row;
    }
    return GestureDetector(
      // opaque, so the empty space between label and value reacts as well
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: row,
    );
  }

  List<Widget> _trailing(BuildContext context) {
    switch (_kind) {
      case _RowKind.toggle:
        return [
          CupertinoSwitch(value: _toggleValue!, onChanged: _onChanged),
        ];
      case _RowKind.value:
        return [
          Text(
            value!,
            style: const TextStyle(
              fontSize: _labelSize,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ];
      case _RowKind.link:
        return [
          Icon(
            CupertinoIcons.arrow_up_right_square,
            size: 16,
            color: CupertinoColors.systemBlue,
          ),
        ];
      case _RowKind.info:
        return [
          Text(
            value!,
            style: TextStyle(
              fontSize: _labelSize,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ];
    }
  }
}

enum _RowKind { toggle, value, link, info }
