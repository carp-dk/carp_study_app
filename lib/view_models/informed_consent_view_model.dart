part of carp_study_app;

/// Whether the user still has to sign informed consent for the active study.
enum ConsentStatus {
  /// Consent is in place - already given, or the study has no document to sign.
  given,

  /// The user has to be shown the [InformedConsentPage] and sign.
  needsSigning,
}

/// View model for [InformedConsentPage] - the consent document, whether the
/// user still has to sign, and recording their accept/reject.
class InformedConsentViewModel extends ViewModel {
  RPOrderedTask? _informedConsent;

  InformedConsentViewModel();

  /// The consent document, once loaded by [getInformedConsent].
  RPOrderedTask? get informedConsent => _informedConsent;

  @override
  void clear() {
    _informedConsent = null;
    super.clear();
  }

  /// The consent document of the active study, or null if it has none.
  Future<RPOrderedTask?> getInformedConsent() async => _informedConsent ??= await bloc.consent.getDocument();

  /// Whether the user still has to sign informed consent.
  ///
  /// A study with no consent document has nothing to sign and is accepted on
  /// the user's behalf, so callers only ever have to act on [needsSigning].
  Future<ConsentStatus> hasBeenAccepted() async {
    if (await _isAccepted) return ConsentStatus.given;

    if (await getInformedConsent() == null) {
      await accept();
      return ConsentStatus.given;
    }
    return ConsentStatus.needsSigning;
  }

  /// Record that the user accepted, uploading the signed [result] when there
  /// was a document to sign.
  Future<void> accept([RPTaskResult? result]) async {
    info('Informed consent has been accepted by user.');
    _acceptedLocally = true;
    if (result != null && !_isLocalDeployment) await bloc.consent.upload(result);
  }

  /// Record that the user declined, and leave the study - without consent there
  /// is nothing to participate in.
  Future<void> reject() async {
    info('Informed consent has been declined by user.');
    _acceptedLocally = false;
    await bloc.leaveStudy();
  }

  // Consent belongs to the account rather than the phone, so a CAWS deployment
  // asks the backend - that also covers consent given on another device. A
  // local deployment has no backend and only has the flag on this phone.
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
