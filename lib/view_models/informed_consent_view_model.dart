part of carp_study_app;

/// View model for [InformedConsentPage] - the document, and accept/reject.
class InformedConsentViewModel extends ViewModel {
  RPOrderedTask? _informedConsent;
  Future<bool>? _needsSigning;

  InformedConsentViewModel();

  /// The consent document, once loaded by [getInformedConsent].
  RPOrderedTask? get informedConsent => _informedConsent;

  /// Does the user still have to sign informed consent?
  ///
  /// Resolved once and cached, since the router asks on every navigation. A
  /// study with no consent document has nothing to sign and is accepted on the
  /// user's behalf.
  Future<bool> needsSigning() async => _needsSigning ??= _resolveNeedsSigning();

  Future<bool> _resolveNeedsSigning() async {
    if (await _isAccepted) return false;

    if (await getInformedConsent() == null) {
      await accept();
      return false;
    }
    return true;
  }

  @override
  void clear() {
    _informedConsent = null;
    _needsSigning = null;
    super.clear();
  }

  /// The consent document of the active study, or null if it has none.
  Future<RPOrderedTask?> getInformedConsent() async => _informedConsent ??= await bloc.consent.getDocument();

  /// Record the accept - only given once the upload it is read back from succeeds.
  ///
  /// Throws when the upload fails: consent that never reached CAWS would be
  /// asked for again on the next launch, so it does not count as given.
  Future<void> accept([RPTaskResult? result]) async {
    if (result != null) await upload(result);

    info('Informed consent has been accepted by user.');
    _acceptedLocally = true;
    _needsSigning = Future.value(false);
  }

  /// Upload the signed [result] - a local deployment has no backend to upload to.
  @protected
  Future<void> upload(RPTaskResult result) async {
    if (_isLocalDeployment) return;
    await bloc.consent.upload(result);
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
