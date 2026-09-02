import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// A Cupertino month grid. Weeks start on Monday; days carry up to
/// [_maxMarkers] markers plus a count of what did not fit. The markers are
/// supplied by the caller, so the grid stays independent of what it shows.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.markers,
    required this.onDaySelected,
  });

  /// Any day inside the month to render.
  final DateTime month;
  final DateTime? selectedDay;

  /// Markers per day, drawn in a [_markerSize] box. Days that are absent
  /// carry no marker.
  final Map<DateTime, List<Widget>> markers;
  final ValueChanged<DateTime> onDaySelected;

  static const int _maxMarkers = 3;
  static const double _markerSize = 16;

  /// 1 January 2024 was a Monday, used to label the weekday header.
  static final DateTime _firstMonday = DateTime(2024, 1, 1);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - DateTime.monday;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++)
        Expanded(child: SizedBox(key: ValueKey('blank-cell-$i'))),
      for (var day = 1; day <= daysInMonth; day++)
        _dayCell(context, DateTime(month.year, month.month, day)),
    ];
    while (cells.length % DateTime.daysPerWeek != 0) {
      cells.add(const Expanded(child: SizedBox()));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _weekdayHeader(context),
        for (var week = 0; week < cells.length ~/ DateTime.daysPerWeek; week++)
          Row(
            children: cells.sublist(
              week * DateTime.daysPerWeek,
              (week + 1) * DateTime.daysPerWeek,
            ),
          ),
      ],
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < DateTime.daysPerWeek; i++)
            Expanded(
              child: Text(
                DateFormat.E().format(_firstMonday.add(Duration(days: i))),
                key: ValueKey('weekday-header-$i'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final isSelected = selectedDay != null && _isSameDay(selectedDay!, day);
    final dayMarkers =
        markers[DateTime(day.year, day.month, day.day)] ?? const <Widget>[];

    return Expanded(
      child: GestureDetector(
        key: ValueKey('day-${_dayKey(day)}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onDaySelected(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: isSelected ? const ValueKey('selected-day') : null,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              SizedBox(
                height: _markerSize + 2,
                child: dayMarkers.isEmpty
                    ? null
                    : _markerRow(context, day, dayMarkers),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _markerRow(BuildContext context, DateTime day, List<Widget> all) {
    final visible = all.take(_maxMarkers).toList();
    final overflow = all.length - visible.length;

    // Cells are narrow and get narrower on small phones, so the row scales
    // down instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        key: ValueKey('markers-${_dayKey(day)}'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final marker in visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: SizedBox(
                width: _markerSize,
                height: _markerSize,
                child: marker,
              ),
            ),
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                '+$overflow',
                style: TextStyle(
                  fontSize: 9,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
