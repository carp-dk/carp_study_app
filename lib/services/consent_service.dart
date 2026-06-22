part of carp_study_app;

/// Manages the informed consent flow: fetching the consent document, checking
/// whether consent has been given, and accepting consent.
///
/// Notifies its listeners when consent is accepted. Listen via the global
/// [bloc], which chains service notifications to the router.
class ConsentService extends ChangeNotifier {
  ConsentService(this._manager, {CarpBackend? backend}) : _backend = backend ?? CarpBackend();

  final InformedConsentManager _manager;
  final CarpBackend _backend;
  bool? _accepted;

  /// Get the informed consent document for this study.
  Future<RPOrderedTask?> getDocument({bool refresh = false}) => _manager.getConsentDocument(refresh: refresh);

  /// The last known consent status, as cached by [refreshStatus] or [accept].
  /// Null until the status has been checked. Used by the router redirect,
  /// which needs a synchronous answer.
  bool? get isAccepted => _accepted;

  /// Check [hasBeenAccepted] for [study], cache the answer in [isAccepted],
  /// and notify. The coordinator supplies the active study.
  Future<bool> refreshStatus(SmartphoneStudy? study) async {
    logApp('ConsentService.refreshStatus() START - deploymentId=${study?.studyDeploymentId}');
    _accepted = await hasBeenAccepted(study);
    logApp('ConsentService.refreshStatus() DONE - isAccepted=$_accepted');
    notifyListeners();
    return _accepted!;
  }

  /// Forget the cached consent status, e.g. when leaving a study.
  void reset() => _accepted = null;

  /// Has the informed consent been accepted by the user for [study]?
  ///
  /// Consent is tied to the account, not the device, so the backend is the
  /// single source of truth in non-local deployments. Local mode has no
  /// backend and falls back to the locally stored flag.
  Future<bool> hasBeenAccepted(SmartphoneStudy? study) async {
    if (AppConfig.deploymentMode == DeploymentMode.local || study == null) {
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
    if (result != null && AppConfig.deploymentMode != DeploymentMode.local) {
      await _backend.uploadInformedConsent(result);
    }
    _accepted = true;
    notifyListeners();
  }
}
