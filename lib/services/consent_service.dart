part of carp_study_app;

/// The backend side of informed consent: the study's consent document and
/// the user's signed consent in CAWS. Policy lives in [InformedConsentViewModel].
class ConsentService {
  ConsentService(this._manager, {CarpBackend? backend}) : _backend = backend ?? CarpBackend();

  final InformedConsentManager _manager;
  final CarpBackend _backend;

  /// Get the informed consent document for this study, or null if it has none.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) => _manager.getConsentDocument(refresh: refresh);

  /// Write the signed consent for [study] to a file the participant can find
  /// again: Downloads on Android, the app's folder in Files on iOS - which is
  /// browsable thanks to `UIFileSharingEnabled`.
  ///
  /// Null when nothing is signed, or the backend cannot be reached.
  Future<File?> downloadSignedConsent(SmartphoneStudy? study) async {
    if (study == null) return null;
    try {
      final consent = await _backend.getInformedConsentByRole(study.studyDeploymentId, study.participantRoleName);
      if (consent == null) return null;
      final dir = (Platform.isAndroid ? await getDownloadsDirectory() : null) ??
          await getApplicationDocumentsDirectory();
      await dir.create(recursive: true);
      return File('${dir.path}/informed_consent.json').writeAsString(toJsonString(consent.toJson()));
    } catch (error) {
      warning('Could not download informed consent - $error');
      return null;
    }
  }

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
