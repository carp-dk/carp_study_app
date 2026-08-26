part of carp_study_app;

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// The localized short weekday name ("Mon") for an ISO [weekday] (1 = Monday).
String weekdayName(BuildContext context, int weekday) => weekday < 1 || weekday > 7
    ? ''
    : RPLocalizations.of(context)!.translate('pages.data_viz.${_weekdayKeys[weekday - 1]}');

/// No tooltip on bar charts: the card's headline names the selection
/// instead. Merely making the background transparent is not enough -
/// fl_chart's default tooltip still prints the raw y-value ("5.2133...")
/// above the touched bar.
BarTouchTooltipData get noBarTooltip => BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => null);

/// Where each of [values] sits in a stacked bar, bottom upwards, as
/// (index, fromY, toY) - skipping zero values, so an absent part of the
/// stack leaves neither a segment nor a [gap] where a segment would be.
List<(int, double, double)> stackSegments(List<num> values, double gap) {
  final segments = <(int, double, double)>[];
  for (final (index, value) in values.indexed) {
    if (value <= 0) continue;
    final from = segments.isEmpty ? 0.0 : segments.last.$3 + gap;
    segments.add((index, from, from + value));
  }
  return segments;
}

/// UI presentation helpers for [MessageType].
///
/// Single source of truth for how a message type is rendered. Returns
/// [IconData] (not a widget) so callers decide colour and size.
extension MessageTypeUI on MessageType {
  /// The icon representing this message type.
  IconData get icon => switch (this) {
    MessageType.announcement => Icons.campaign,
    MessageType.news => Icons.newspaper,
    MessageType.article => Icons.article,
  };
}
