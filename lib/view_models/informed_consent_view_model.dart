part of carp_study_app;

/// Whether the user still has to sign informed consent for the active study.
enum ConsentStatus {
  /// Not resolved yet - [InformedConsentViewModel.resolve] is still running.
  resolving,

  /// Consent is in place - already given, or the study has no document to sign.
  given,

  /// The user has to be shown the [InformedConsentPage] and sign.
  needsSigning,

  /// Consent could not be resolved, e.g. the document could not be loaded.
  failed,
}

/// View model for [InformedConsentPage] - the document, the status, accept/reject.
class InformedConsentViewModel extends ViewModel {
  RPOrderedTask? _informedConsent;
  ConsentStatus _status = ConsentStatus.resolving;

  InformedConsentViewModel();

  /// The consent document, once loaded by [getInformedConsent].
  RPOrderedTask? get informedConsent => _informedConsent;

  /// Whether consent still has to be signed - what [CarpAppShell] shows on.
  ConsentStatus get status => _status;

  /// Resolve [status], loading the consent document if there is one to sign.
  Future<void> resolve() async {
    try {
      _status = await hasBeenAccepted();
    } catch (error) {
      warning('$runtimeType - could not resolve informed consent - $error');
      _status = ConsentStatus.failed;
    }
    notifyListeners();
  }

  @override
  void clear() {
    _informedConsent = null;
    _status = ConsentStatus.resolving;
    super.clear();
  }

  /// The consent document of the active study, or null if it has none.
  Future<RPOrderedTask?> getInformedConsent() async => _informedConsent ??= await bloc.consent.getDocument();

  /// Whether consent still has to be signed - no document means nothing to sign.
  Future<ConsentStatus> hasBeenAccepted() async {
    final accepted = await _isAccepted;
    if (accepted) return ConsentStatus.given;

    if (await getInformedConsent() == null) {
      await accept();
      return ConsentStatus.given;
    }
    return ConsentStatus.needsSigning;
  }

  /// Record the accept - only given once the upload it is read back from succeeds.
  Future<void> accept([RPTaskResult? result]) async {
    if (result != null && !_isLocalDeployment) {
      await bloc.consent.upload(result);
    }
    info('Informed consent has been accepted by user.');
    _acceptedLocally = true;
    _status = ConsentStatus.given;
    notifyListeners();
  }

  /// Record the decline and leave the study - without consent there is no study.
  Future<void> reject() async {
    info('Informed consent has been declined by user.');
    _acceptedLocally = false;
    await bloc.leaveStudy();
  }

  // Consent belongs to the account, so CAWS is asked; local has only this flag.
  Future<bool> get _isAccepted async =>
      _isLocalDeployment ? _acceptedLocally : await bloc.consent.hasSignedConsent(bloc.study.study);

  bool get _isLocalDeployment => AppConfig.deploymentMode == DeploymentMode.local;

  bool get _acceptedLocally => LocalSettings().participant?.hasInformedConsentBeenAccepted ?? false;

  set _acceptedLocally(bool accepted) {
    final participant = LocalSettings().participant;
    participant?.hasInformedConsentBeenAccepted = accepted;
    LocalSettings().participant = participant;
  }
}
