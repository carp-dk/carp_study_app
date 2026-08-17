part of carp_study_app;

/// The backend side of informed consent: fetching the consent document of the
/// study, and reading / writing the user's signed consent in CAWS.
///
/// Deployment-mode policy and the locally stored flag are not this layer's
/// concern - see [InformedConsentViewModel].
class ConsentService {
  ConsentService(this._manager, {CarpBackend? backend}) : _backend = backend ?? CarpBackend();

  final InformedConsentManager _manager;
  final CarpBackend _backend;

  /// Get the informed consent document for this study, or null if it has none.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) => _manager.getConsentDocument(refresh: refresh);

  /// Has a signed informed consent been uploaded for [study]?
  ///
  /// False if there is no study, or if the backend cannot be reached - the user
  /// is then asked to sign again rather than being let in on a guess.
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
  Future<void> upload(RPTaskResult result) => _backend.uploadInformedConsent(result);
}
