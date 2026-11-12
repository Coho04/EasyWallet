import 'package:easy_wallet/class/icon_image.dart';
import 'package:easy_wallet/model/subscription_icon.dart';
import 'package:easy_wallet/views/components/color_picker_sheet.dart';
import 'package:easy_wallet/views/components/subscription_icon_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// What the icon picker came back with. [icon] is null when the user chose to
/// go back to the website icon; a cancelled picker returns no choice at all.
class IconChoice {
  const IconChoice(this.icon);

  final SubscriptionIcon? icon;
}

enum _IconSource { symbol, emoji, image, website }

/// Colours offered next to the symbols. One tap instead of a colour wheel for
/// the common case; the wheel is still there for everything else.
const List<Color> _symbolColors = [
  CupertinoColors.systemBlue,
  CupertinoColors.systemIndigo,
  CupertinoColors.systemPurple,
  CupertinoColors.systemPink,
  CupertinoColors.systemRed,
  CupertinoColors.systemOrange,
  CupertinoColors.systemYellow,
  CupertinoColors.systemGreen,
  CupertinoColors.systemTeal,
  CupertinoColors.systemBrown,
  CupertinoColors.systemGrey,
  CupertinoColors.black,
];

const List<String> _commonEmojis = [
  '📺',
  '🎬',
  '🍿',
  '🎵',
  '🎧',
  '🎮',
  '📚',
  '📰',
  '☁️',
  '💻',
  '📱',
  '🌐',
  '🔒',
  '🤖',
  '📷',
  '✉️',
  '🛡️',
  '🏦',
  '💳',
  '💰',
  '📈',
  '🚗',
  '⛽',
  '🚆',
  '✈️',
  '🚲',
  '🏋️',
  '⚽',
  '❤️',
  '💊',
  '🛒',
  '📦',
  '🍕',
  '☕',
  '🏠',
  '⚡',
  '💧',
  '🔥',
  '🎓',
  '🐶',
  '👶',
  '🎁',
  '⭐',
  '💼',
];

/// Asks how the subscription should be shown, in the Cupertino modal popup
/// shape the app uses for its pickers (see [showColorPickerSheet]).
///
/// Returns null when the user backs out at any step, so the caller can tell
/// "nothing changed" apart from "back to the website icon".
Future<IconChoice?> showIconPickerSheet(
  BuildContext context, {
  SubscriptionIcon? current,
}) async {
  final source = await showCupertinoModalPopup<_IconSource>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(Intl.message('chooseIcon')),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, _IconSource.symbol),
          child: Text(Intl.message('iconSymbol')),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, _IconSource.emoji),
          child: Text(Intl.message('iconEmoji')),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, _IconSource.image),
          child: Text(Intl.message('iconImage')),
        ),
        if (current != null)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, _IconSource.website),
            child: Text(Intl.message('iconFromWebsite')),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(Intl.message('cancel')),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  switch (source) {
    case _IconSource.symbol:
      final icon = await _pickSymbol(context, current);
      return icon == null ? null : IconChoice(icon);
    case _IconSource.emoji:
      final icon = await _pickEmoji(context, current);
      return icon == null ? null : IconChoice(icon);
    case _IconSource.image:
      final icon = await _pickImage(context);
      return icon == null ? null : IconChoice(icon);
    case _IconSource.website:
      return const IconChoice(null);
  }
}

Future<SubscriptionIcon?> _pickSymbol(
  BuildContext context,
  SubscriptionIcon? current,
) {
  var color = current?.kind == IconKind.symbol
      ? current!.symbolColor
      : CupertinoColors.systemBlue;

  return showCupertinoModalPopup<SubscriptionIcon>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Widget swatch(Color option) {
          final selected = option.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => color = option),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: option,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? CupertinoColors.label.resolveFrom(context)
                      : CupertinoColors.separator.resolveFrom(context),
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        }

        return _SheetFrame(
          title: Intl.message('chooseSymbol'),
          height: 500,
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final option in _symbolColors) swatch(option),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () async {
                        final picked = await showColorPickerSheet(
                          context,
                          color,
                        );
                        if (picked != null) setState(() => color = picked);
                      },
                      child: Icon(
                        CupertinoIcons.paintbrush,
                        semanticLabel: Intl.message('pickAColor'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 6,
                  padding: const EdgeInsets.all(12),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final key in iconSymbols.keys)
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          SubscriptionIcon.symbol(key, color),
                        ),
                        child: SubscriptionIconView(
                          icon: SubscriptionIcon.symbol(key, color),
                          width: 44,
                          height: 44,
                          borderRadius: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<SubscriptionIcon?> _pickEmoji(
  BuildContext context,
  SubscriptionIcon? current,
) {
  return showCupertinoModalPopup<SubscriptionIcon>(
    context: context,
    builder: (context) => _EmojiSheet(
      initial: current?.kind == IconKind.emoji ? current!.value : '',
    ),
  );
}

/// A field for any single character plus the emojis subscriptions most often
/// get. Stateful because it owns the field's controller, which has to outlive
/// the closing animation of the popup.
class _EmojiSheet extends StatefulWidget {
  const _EmojiSheet({required this.initial});

  final String initial;

  @override
  State<_EmojiSheet> createState() => _EmojiSheetState();
}

class _EmojiSheetState extends State<_EmojiSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final emoji = _controller.text.trim();
    Navigator.pop(
      context,
      emoji.isEmpty ? null : SubscriptionIcon.emoji(emoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: Intl.message('chooseEmoji'),
      height: 460,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoTextField(
              controller: _controller,
              placeholder: Intl.message('emojiPlaceholder'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28),
              onChanged: (value) {
                // One icon is one character as the user sees it. A flag or a
                // family emoji is several code points, so counting anything
                // else would cut them apart.
                final chars = value.characters;
                if (chars.length > 1) {
                  _controller.text = chars.last;
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 8,
              padding: const EdgeInsets.all(12),
              children: [
                for (final emoji in _commonEmojis)
                  GestureDetector(
                    onTap: () =>
                        Navigator.pop(context, SubscriptionIcon.emoji(emoji)),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: _submit,
            child: Text(Intl.message('done')),
          ),
        ],
      ),
    );
  }
}

Future<SubscriptionIcon?> _pickImage(BuildContext context) async {
  try {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    final bytes = await downscaleIconImage(await file.readAsBytes());
    return SubscriptionIcon.image(bytes);
  } catch (e) {
    debugPrint('Could not use the picked picture: $e');
    if (context.mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(Intl.message('error')),
          content: Text(Intl.message('iconImageFailed')),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return null;
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.height,
    required this.child,
  });

  final String title;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Lifted above the keyboard, which the emoji field brings up.
      height: height + MediaQuery.viewInsetsOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The icon next to the title field of the create and edit forms. Shows what
/// the subscription will look like and opens [showIconPickerSheet] on tap.
class SubscriptionIconPicker extends StatelessWidget {
  const SubscriptionIconPicker({
    super.key,
    required this.icon,
    required this.url,
    required this.onChanged,
  });

  final SubscriptionIcon? icon;
  final String url;
  final ValueChanged<SubscriptionIcon?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: Intl.message('chooseIcon'),
      child: GestureDetector(
        onTap: () async {
          final choice = await showIconPickerSheet(context, current: icon);
          if (choice != null) onChanged(choice.icon);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SubscriptionIconView(
              icon: icon,
              url: url,
              fallback: CupertinoIcons.creditcard,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 10,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
