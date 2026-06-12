part of carp_study_app;

class InformedConsentViewModel extends ViewModel {
  RPOrderedTask? _informedConsent;

  InformedConsentViewModel();

  @override
  void clear() {
    _informedConsent = null;
    super.clear();
  }

  /// Get the informed consent for this study as translated to the
  /// local [locale].
  Future<RPOrderedTask?> getInformedConsent(Locale locale) async {
    if (_informedConsent == null) {
      await bloc.resources.localizationLoader.load(locale);
      _informedConsent = await bloc.consent.getDocument();
    }
    return _informedConsent;
  }

  /// Called when the informed consent has been accepted by the user.
  /// Returns once the upload to the backend has completed, so callers can
  /// safely route to a page whose redirect re-queries the backend.
  Future<void> informedConsentHasBeenAccepted(RPTaskResult informedConsentResult) =>
      bloc.consent.accept(informedConsentResult);
}
