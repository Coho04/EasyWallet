import 'package:easy_wallet/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// The card the guided tour puts over the app, explaining the screen behind it.
///
/// Purely presentational: it is told what to say and what to call, and knows
/// nothing about tabs or where in the tour it sits. The screen underneath
/// stays visible through the scrim on purpose — the point of the tour is to
/// look at the real app, not at a picture of it.
class TourOverlay extends StatelessWidget {
  const TourOverlay({
    super.key,
    required this.title,
    required this.body,
    required this.stepNumber,
    required this.stepCount,
    required this.onNext,
    required this.onSkip,
  });

  final String title;
  final String body;
  final int stepNumber;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  bool get _isOnLastStep => stepNumber >= stepCount;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        container: true,
        child: Stack(
          children: [
            // Swallows taps as well as dimming: the app underneath must not
            // react while the tour is talking about it.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: const ColoredBox(color: Color(0x99000000)),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _card(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).tourProgress(stepNumber, stepCount),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          _dots(),
          const SizedBox(height: 12),
          Row(
            children: [
              // Always reachable, including on the last step: someone who has
              // seen enough should never have to click through to the end.
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onSkip,
                child: Text(
                  Intl.message('tourSkip'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
              const Spacer(),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                sizeStyle: CupertinoButtonSize.small,
                onPressed: onNext,
                child: Text(
                  _isOnLastStep
                      ? Intl.message('tourDone')
                      : Intl.message('tourNext'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One dot per station, so the length of the tour is visible at a glance.
  Widget _dots() {
    return Row(
      children: [
        for (var i = 1; i <= stepCount; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == stepNumber
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
              ),
            ),
          ),
      ],
    );
  }
}
