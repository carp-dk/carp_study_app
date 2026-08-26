part of carp_study_app;

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// The localized short weekday name ("Mon") for an ISO [weekday] (1 = Monday).
String weekdayName(BuildContext context, int weekday) => weekday < 1 || weekday > 7
    ? ''
    : RPLocalizations.of(context)!.translate('pages.data_viz.${_weekdayKeys[weekday - 1]}');

/// No tooltip on bar charts - the card's headline names the selection instead.
BarTouchTooltipData get noBarTooltip => BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => null);

/// Where each of [values] sits in a stacked bar, bottom upwards, as
/// (index, fromY, toY) - zero values leave neither a segment nor a [gap].
List<(int, double, double)> stackSegments(List<num> values, double gap) {
  final segments = <(int, double, double)>[];
  for (final (index, value) in values.indexed) {
    if (value <= 0) continue;
    final from = segments.isEmpty ? 0.0 : segments.last.$3 + gap;
    segments.add((index, from, from + value));
  }
  return segments;
}

/// How a message type is rendered - [IconData], so callers decide colour/size.
extension MessageTypeUI on MessageType {
  /// The icon representing this message type.
  IconData get icon => switch (this) {
    MessageType.announcement => Icons.campaign,
    MessageType.news => Icons.newspaper,
    MessageType.article => Icons.article,
  };
}
