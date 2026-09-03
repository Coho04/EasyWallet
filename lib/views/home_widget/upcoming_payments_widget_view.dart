import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:flutter/cupertino.dart';

/// The list drawn onto the home screen widget.
///
/// Rendered to an image by HomeWidgetBridge, so it must lay out in one pass:
/// every image it draws has to be in the cache already.
class UpcomingPaymentsWidgetView extends StatelessWidget {
  const UpcomingPaymentsWidgetView({
    super.key,
    required this.payments,
    required this.icons,
    required this.currencySymbol,
    required this.showAmount,
    required this.emptyLabel,
    required this.headline,
  });

  final List<UpcomingPayment> payments;

  /// Favicon per subscription id, already loaded.
  final Map<int, ImageProvider> icons;
  final String currencySymbol;
  final bool showAmount;
  final String emptyLabel;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF2F2F7),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 6),
            if (payments.isEmpty)
              Text(
                emptyLabel,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              )
            else
              for (final payment in payments) _row(payment),
          ],
        ),
      ),
    );
  }

  Widget _row(UpcomingPayment payment) {
    final icon = icons[payment.subscription.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Days first: the number is what the glance is for.
          SizedBox(
            width: 34,
            child: Text(
              payment.daysUntil == 0 ? '·' : '${payment.daysUntil}d',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: payment.daysUntil <= 2
                    ? const Color(0xFFFF3B30)
                    : payment.daysUntil <= 7
                        ? const Color(0xFFFF9500)
                        : const Color(0xFF8E8E93),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: icon == null
                  ? Container(color: const Color(0xFFD1D1D6))
                  : Image(image: icon, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              payment.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF000000)),
            ),
          ),
          if (showAmount) ...[
            const SizedBox(width: 6),
            Text(
              Money.format(payment.amount, currencySymbol),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
