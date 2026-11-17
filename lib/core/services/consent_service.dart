import 'dart:async';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/backend/backend.dart';

/// The consent document and signed consent in CAWS - policy is the view model's.
class ConsentService {
  ConsentService(this._manager, {Backend? backend}) : _backend = backend ?? Backend();

  final InformedConsentManager _manager;
  final Backend _backend;

  /// Get the informed consent document for this study, or null if it has none.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) async {
    final json = await _manager.getConsentDocument(refresh: refresh);
    return json == null ? null : RPOrderedTask.fromJson(json);
  }

  /// The signed consent for [study], or null when nothing is signed or the
  /// backend cannot be reached - the user is then asked to sign again.
  Future<InformedConsentInput?> signedConsent(SmartphoneStudy? study) async {
    if (study == null) return null;
    try {
      return await _backend.getInformedConsentByRole(study.studyDeploymentId, study.participantRoleName);
    } catch (error) {
      warning('Could not fetch informed consent - $error');
      return null;
    }
  }

  Future<bool> hasSignedConsent(SmartphoneStudy? study) async => await signedConsent(study) != null;

  /// Upload the signed consent [result] to CAWS.
  Future<void> upload(RPTaskResult result) => _backend.uploadInformedConsent(result).timeout(Duration(seconds: 20));
}
