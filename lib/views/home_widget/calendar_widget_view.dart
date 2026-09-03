import 'package:easy_wallet/views/components/month_grid.dart';
import 'package:flutter/cupertino.dart';

/// The month grid drawn onto the home screen widget. Reuses the grid the
/// calendar tab uses, so both show the month the same way.
class CalendarWidgetView extends StatelessWidget {
  const CalendarWidgetView({
    super.key,
    required this.month,
    required this.markers,
    required this.headline,
    required this.total,
  });

  final DateTime month;
  final Map<DateTime, List<Widget>> markers;
  final String headline;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF2F2F7),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            MonthGrid(
              month: month,
              selectedDay: null,
              markers: markers,
              onDaySelected: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
