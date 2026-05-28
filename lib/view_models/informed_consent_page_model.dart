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
      await bloc.localizationLoader.load(locale);
      _informedConsent = await bloc.getInformedConsent();
    }
    return _informedConsent;
  }

  /// Called when the informed consent has been accepted by the user.
  void informedConsentHasBeenAccepted(
    RPTaskResult informedConsentResult,
  ) =>
      bloc.informedConsentHasBeenAccepted(informedConsentResult);
}
