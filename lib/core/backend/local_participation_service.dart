import 'dart:async';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_study_app/core/util/app_config.dart';

/// A local [ParticipationService] that does not connect to any backend.
/// This is used when running in [DeploymentMode.local].
class LocalParticipationService implements ParticipationService {
  static final LocalParticipationService _instance = LocalParticipationService._();

  LocalParticipationService._();

  /// Returns the singleton default instance of the [LocalParticipationService].
  factory LocalParticipationService() => _instance;

  @override
  Future<List<ActiveParticipationInvitation>> getActiveParticipationInvitations({String? accountId}) async => [];

  // ponytail: in memory, like the local consent - asked again after an app restart.
  final Map<String, Map<String, Data?>> _data = {};

  /// Forget all participant data - used by Reset local data.
  void clear() => _data.clear();

  @override
  Future<ParticipantData> getParticipantData(String studyDeploymentId) async =>
      ParticipantData(studyDeploymentId: studyDeploymentId, common: {...?_data[studyDeploymentId]});

  @override
  Future<List<ParticipantData>> getParticipantDataList(List<String> studyDeploymentIds) async => [
    for (final id in studyDeploymentIds) await getParticipantData(id),
  ];

  @override
  Future<ParticipantData> setParticipantData(
    String studyDeploymentId,
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]) async {
    (_data[studyDeploymentId] ??= {}).addAll(data);
    return getParticipantData(studyDeploymentId);
  }
}
