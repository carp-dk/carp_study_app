import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/settings/local_settings.dart';

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
    if (LocalSettings().study == null) return translations;

    try {
      translations = await localizationManager.getLocalizations(locale) ?? {};
      info("$runtimeType - translations for ´$locale' loaded.");
    } catch (error) {
      warning("$runtimeType - could not load translations for '$locale' - $error");
    }

    return translations;
  }
}
