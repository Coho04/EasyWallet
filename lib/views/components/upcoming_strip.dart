import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';

class UpcomingStrip extends StatelessWidget {
  const UpcomingStrip({
    super.key,
    required this.upcomingSubscriptions,
    required this.currencySymbol,
  });

  final List<Subscription> upcomingSubscriptions;
  final String currencySymbol;

  Color _daysColor(int days) {
    if (days <= 2) return const Color(0xFFFF3B30);
    if (days <= 5) return const Color(0xFFFF9500);
    return const Color(0xFF8E8E93);
  }

  @override
  Widget build(BuildContext context) {
    if (upcomingSubscriptions.isEmpty) return const SizedBox.shrink();

    return Container(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: Text(
              'NÄCHSTE 7 TAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              itemCount: upcomingSubscriptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sub = upcomingSubscriptions[index];
                final days = sub.remainingDays();
                return Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      sub.buildImage(width: 28, height: 28, borderRadius: 7),
                      const SizedBox(height: 4),
                      Text(
                        sub.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '$days T',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: days <= 2 ? FontWeight.w700 : FontWeight.w400,
                          color: _daysColor(days),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
