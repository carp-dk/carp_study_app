part of carp_study_app;

/// Fetches raw measurements from CAWS for the trailing week, for the
/// Statistics page to backfill its cards with.
class DataStreamQueryService {
  static const Duration window = Duration(days: 7);

  /// Fetch measurements for [dataType] over the last [window], or null on
  /// any failure (offline, 404, unauthenticated) - backfill is best-effort,
  /// never blocks the page. Null is not an empty result: a card rebuilds
  /// itself from what it is given, so handing it `[]` after a failed fetch
  /// would wipe the data it already has.
  ///
  /// [deviceRoleName] is the role of the device that produced [dataType] -
  /// the phone's role for phone-sourced probes (Steps, Activity), but a
  /// connected device's own role (e.g. "Polar HR Sensor") for anything
  /// sourced from hardware, since the deployment records data per-device.
  /// Defaults to the phone.
  Future<List<Measurement>?> fetch(String dataType, {String? deviceRoleName}) async {
    final study = LocalSettings().study;
    if (study == null || !CarpBackend().isAuthenticated) return null;

    final to = DateTime.now();
    final from = to.subtract(window);
    final id = DataStreamId(
      studyDeploymentId: study.studyDeploymentId,
      deviceRoleName: deviceRoleName ?? study.deviceRoleName,
      dataType: dataType,
    );

    try {
      // A data stream comes back as one batch per contiguous run of
      // measurements, so flatten them into a single list.
      final batches = await CarpDataStreamService().dataStream(study.studyDeploymentId).getByTime(id, from, to);
      final measurements = batches.expand((batch) => batch.measurements);
      // The backend filters by upload time, not sensor time - a measurement
      // synced late (e.g. after time offline) can carry a sensor timestamp
      // from outside [from, to]. The cards bucket by weekday only, so a
      // stray old reading would land in the wrong day; drop anything whose
      // own timestamp falls outside the window we asked for.
      return measurements.where((m) => !m.dateTime.isBefore(from) && !m.dateTime.isAfter(to)).toList();
    } catch (error) {
      warning('$runtimeType - failed to fetch $dataType: $error');
      return null;
    }
  }
}
