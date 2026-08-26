part of carp_study_app;

extension MeasurementTime on Measurement {
  /// When this measurement was taken, as local time - bucket by this,
  /// never by `DateTime.now()`, or replayed data lands in the present.
  DateTime get sensorTime => DateTime.fromMicrosecondsSinceEpoch(sensorStartTime);
}

extension StringExtension on String {
  String truncateTo(int maxLength) => (length <= maxLength) ? this : '${substring(0, maxLength)}...';
}

extension Humanize on Duration {
  String humanize(RPLocalizations locale) {
    // Convert the difference into a human-readable format and round up
    if (inSeconds < 60) {
      return _pluralize(inSeconds, locale, 'seconds');
    } else if (inMinutes < 60) {
      int roundedMinutes = (inSeconds / 60).round();
      return _pluralize(roundedMinutes, locale, 'minutes');
    } else if (inHours < 24) {
      int roundedHours = (inSeconds / 3600).round();
      return _pluralize(roundedHours, locale, 'hours');
    } else {
      int roundedDays = (inSeconds / 86400).round();
      return _pluralize(roundedDays, locale, 'days');
    }
  }

  String _pluralize(int n, RPLocalizations locale, String unit) {
    String translationKey = "pages.task_list.task.${unit}_remaining";

    if (n != 1) {
      translationKey += "_plural";
    }

    return "$n ${locale.translate(translationKey)}";
  }
}
