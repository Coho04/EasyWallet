import 'package:flutter/cupertino.dart';

class BudgetWarningBanner extends StatelessWidget {
  const BudgetWarningBanner({
    super.key,
    required this.spent,
    required this.limit,
    required this.currencySymbol,
  });

  final double spent;
  final double limit;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final over = spent - limit;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x26FF3B30),
          border: Border.all(color: const Color(0x59FF3B30)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0x40FF3B30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Color(0xFFFF6B6B),
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monatsbudget überschritten',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                Text(
                  'Limit $currencySymbol ${limit.toStringAsFixed(2)} · +$currencySymbol ${over.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xA8FF6B6B),
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
