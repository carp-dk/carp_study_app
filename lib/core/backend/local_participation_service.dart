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

  @override
  Future<ParticipantData> getParticipantData(String studyDeploymentId) async =>
      ParticipantData(studyDeploymentId: studyDeploymentId);

  @override
  Future<List<ParticipantData>> getParticipantDataList(List<String> studyDeploymentIds) async => [];

  @override
  Future<ParticipantData> setParticipantData(
    String studyDeploymentId,
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]) async => ParticipantData(studyDeploymentId: studyDeploymentId);
}
