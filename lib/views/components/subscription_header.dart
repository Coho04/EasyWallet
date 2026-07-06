import 'package:easy_wallet/views/components/budget_warning_banner.dart';
import 'package:flutter/cupertino.dart';

class SubscriptionHeader extends StatelessWidget {
  const SubscriptionHeader({
    super.key,
    required this.monthlySpent,
    required this.yearlySpent,
    required this.currencySymbol,
    this.budgetLimit,
    required this.onSortTap,
    required this.onAddTap,
  });

  final double monthlySpent;
  final double yearlySpent;
  final String currencySymbol;
  final double? budgetLimit;
  final VoidCallback onSortTap;
  final VoidCallback onAddTap;

  bool get _budgetExceeded =>
      budgetLimit != null && budgetLimit! > 0 && monthlySpent > budgetLimit!;

  double get _budgetProgress =>
      (budgetLimit != null && budgetLimit! > 0)
          ? (monthlySpent / budgetLimit!).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGradientHeader(),
        if (_budgetExceeded)
          BudgetWarningBanner(
            spent: monthlySpent,
            limit: budgetLimit!,
            currencySymbol: currencySymbol,
          ),
      ],
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSortTap,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
              const Text(
                'EasyWallet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onAddTap,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpendCard('Diesen Monat', monthlySpent, currencySymbol)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpendCard('Dieses Jahr', yearlySpent, currencySymbol)),
            ],
          ),
          if (budgetLimit != null && budgetLimit! > 0) ...[
            const SizedBox(height: 10),
            _buildBudgetBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpendCard(String label, double value, String symbol) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0x8CFFFFFF),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$symbol ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color get _barColor => _budgetProgress >= 1.0
      ? const Color(0xFFFF3B30)
      : _budgetProgress >= 0.8
          ? const Color(0xFFFF9500)
          : const Color(0xFF30D158);

  Widget _buildBudgetBar() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _budgetProgress,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _budgetExceeded
              ? '$currencySymbol ${(monthlySpent - budgetLimit!).toStringAsFixed(2)} über'
              : '${(100 * _budgetProgress).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Color(0x72FFFFFF)),
        ),
      ],
    );
  }
}
