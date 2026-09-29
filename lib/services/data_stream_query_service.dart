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
    if (study == null || !CarpBackend().isAuthenticated) {
      info('[STATS-DEBUG] fetch $dataType/$deviceRoleName skipped - study: ${study?.studyDeploymentId}, authenticated: ${CarpBackend().isAuthenticated}');
      return null;
    }

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
      final kept = measurements.where((m) => !m.sensorTime.isBefore(from) && !m.sensorTime.isAfter(to)).toList();
      info('[STATS-DEBUG] fetch $dataType/$deviceRoleName deployment ${study.studyDeploymentId} $from..$to - '
          '${batches.length} batches, ${measurements.length} measurements, ${kept.length} in window, types: ${_countTypes(kept)}');
      return kept;
    } catch (error) {
      warning('$runtimeType - failed to fetch $dataType for $deviceRoleName: $error');
      return null;
    }
  }

  // [STATS-DEBUG] count per health type (or data type), e.g. {HEART_RATE: 120, SLEEP_REM: 4}.
  static Map<String, int> _countTypes(List<Measurement> measurements) {
    final counts = <String, int>{};
    for (final m in measurements) {
      final data = m.data;
      final type = data is HealthData ? data.healthDataType : m.dataType.name;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
