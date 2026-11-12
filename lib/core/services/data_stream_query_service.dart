part of carp_study_app;

/// Fetches raw measurements from CAWS for the trailing week, for the
/// Statistics page to backfill its cards with.
class DataStreamQueryService {
  static const Duration window = Duration(days: 7);

  /// Fetch measurements for [dataType] streamed under [deviceRoleName] over
  /// the last [window], or null on any failure - null (not `[]`) so a failed
  /// fetch never wipes existing card data.
  Future<List<Measurement>?> fetch(String dataType, String deviceRoleName) async {
    final study = LocalSettings().study;
    if (study == null || !CarpBackend().isAuthenticated) return null;

    final to = DateTime.now();
    final from = to.subtract(window);
    final id = DataStreamId(
      studyDeploymentId: study.studyDeploymentId,
      deviceRoleName: deviceRoleName,
      dataType: dataType,
    );

    try {
      final batches = await CarpDataStreamService()
          .dataStream(study.studyDeploymentId)
          .getDataStreamBatchesByTime(id, from, to);
      final measurements = batches.expand((batch) => batch.measurements);
      // Backend filters by upload time; drop late-synced measurements whose
      // sensor timestamp falls outside the window.
      return measurements.where((m) => !m.sensorTime.isBefore(from) && !m.sensorTime.isAfter(to)).toList();
    } catch (error) {
      warning('$runtimeType - failed to fetch $dataType for $deviceRoleName: $error');
      return null;
    }
  }
}
