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
  /// Throws when the upload fails: consent that never reached the backend would be
  /// asked for again on the next launch, so it does not count as given.
  Future<void> accept([RPTaskResult? result]) async {
    if (result != null) await upload(result);

    info('Informed consent has been accepted by user.');
    _needsSigning = Future.value(false);
  }

  /// Upload the signed [result] to the backend.
  @protected
  Future<void> upload(RPTaskResult result) => bloc.consent.upload(result);

  /// Record the decline and leave the study - without consent there is no study.
  Future<void> reject() async {
    info('Informed consent has been declined by user.');
    await bloc.leaveStudy();
  }

  // Consent belongs to the account, so the backend is asked.
  Future<bool> get _isAccepted => bloc.consent.hasSignedConsent(bloc.study.study);
}
