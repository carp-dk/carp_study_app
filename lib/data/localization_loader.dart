part of carp_study_app;

/// A [LocalizationLoader] that knows how to load localizations from a
/// [LocalizationManager].
class ResourceLocalizationLoader implements LocalizationLoader {
  final LocalizationManager localizationManager;
  ResourceLocalizationLoader(this.localizationManager);

  @override
  Future<Map<String, String>> load(Locale locale) async {
    Map<String, String> translations = {};

    // Study-specific translations only exist once a study is selected -
    // the CARP resource manager needs the study deployment id to look them up.
    if (!bloc.study.hasStudy) return translations;

    try {
      translations = await localizationManager.getLocalizations(locale) ?? {};
      info("$runtimeType - translations for ´$locale' loaded.");
    } catch (error) {
      warning("$runtimeType - could not load translations for '$locale' - $error");
    }

    return translations;
  }
}
