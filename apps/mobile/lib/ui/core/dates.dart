import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days from [from] to [to] (negative = [to] is earlier).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Weeks start Monday (id locale defaults to Sunday).
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - d.weekday + 1);

final _dayLabel = DateFormat('EEE, d MMM', 'id');

/// "sel, 13 okt".
String dayLabel(DateTime d) => _dayLabel.format(d).toLowerCase();

/// "hari ini" · "kemarin" · "3 hari lalu" · "minggu lalu" …, for [day]
/// relative to [today].
String relativeDay(AppLocalizations l, DateTime day, DateTime today) {
  final n = daysBetween(today, day);
  return switch (n) {
    0 => l.today,
    -1 => l.yesterday,
    -2 => l.twoDaysAgo,
    > -7 => l.daysAgo(-n),
    > -14 => l.lastWeek,
    _ => l.weeksAgo((-n / 7).round()),
  };
}

final _dayMonth = DateFormat('d MMM', 'id');

/// "25 sep – 22 okt": a period's first and last day ([end] is exclusive).
String periodRange(DateTime start, DateTime end) =>
    '${_dayMonth.format(start)} – '
            '${_dayMonth.format(DateTime(end.year, end.month, end.day - 1))}'
        .toLowerCase();
