part of carp_study_app;

/// The consent document and signed consent in CAWS - policy is the view model's.
class ConsentService {
  ConsentService(this._manager, {CarpBackend? backend}) : _backend = backend ?? CarpBackend();

  final InformedConsentManager _manager;
  final CarpBackend _backend;

  /// Get the informed consent document for this study, or null if it has none.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) => _manager.getConsentDocument(refresh: refresh);

  /// Has a signed consent been uploaded for [study]? False if it can't be checked.
  Future<bool> hasSignedConsent(SmartphoneStudy? study) async {
    if (study == null) return false;
    try {
      final consent = await _backend.getInformedConsentByRole(study.studyDeploymentId, study.participantRoleName);
      return consent != null;
    } catch (error) {
      warning('Could not fetch informed consent status from backend - $error');
      return false;
    }
  }

  /// Upload the signed consent [result] to CAWS.
  Future<void> upload(RPTaskResult result) => _backend.uploadInformedConsent(result).timeout(Duration(seconds: 20));
}
