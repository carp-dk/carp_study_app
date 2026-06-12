part of carp_study_app;

/// Manages the informed consent flow: fetching the consent document, checking
/// whether consent has been given, and accepting consent.
///
/// Notifies its listeners when consent is accepted. Listen via the global
/// [bloc], which chains service notifications to the router.
class ConsentService extends ChangeNotifier {
  ConsentService(this._manager, this._studyService, {AppConfig? config, CarpBackend? backend})
    : _config = config ?? AppConfig(),
      _backend = backend ?? CarpBackend();

  final InformedConsentManager _manager;
  final StudyService _studyService;
  final AppConfig _config;
  final CarpBackend _backend;

  /// Get the informed consent document for this study.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) => _manager.getConsentDocument(refresh: refresh);

  /// Has the informed consent been accepted by the user?
  ///
  /// Consent is tied to the account, not the device, so the backend is the
  /// single source of truth in non-local deployments. Local mode has no
  /// backend and falls back to the locally stored flag.
  Future<bool> get hasBeenAccepted async {
    final study = _studyService.study;
    if (_config.deploymentMode == DeploymentMode.local || study == null) {
      return LocalSettings().participant?.hasInformedConsentBeenAccepted ?? false;
    }
    try {
      final consent = await _backend.getInformedConsentByRole(study.studyDeploymentId, study.participantRoleName);
      return consent != null;
    } catch (e) {
      warning('Could not fetch informed consent status from backend: $e');
      return false;
    }
  }

  /// Mark the informed consent as accepted: persist locally and (when online)
  /// upload the signed [result] to CAWS. Pass `null` when the study has no
  /// consent document - only the local flag is set.
  Future<void> accept([RPTaskResult? result]) async {
    info('Informed consent has been accepted by user.');
    var participant = LocalSettings().participant;
    participant?.hasInformedConsentBeenAccepted = true;
    LocalSettings().participant = participant;
    if (result != null && _config.deploymentMode != DeploymentMode.local) {
      await _backend.uploadInformedConsent(result);
    }
    notifyListeners();
  }
}
