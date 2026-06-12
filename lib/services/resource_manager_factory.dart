part of carp_study_app;

/// Provides the resource managers matching the current [DeploymentMode]:
/// local resources in [DeploymentMode.local], CAWS-backed resources otherwise.
///
/// Instances are created once and cached.
class ResourceManagerFactory {
  ResourceManagerFactory({AppConfig? config}) : _config = config ?? AppConfig();

  final AppConfig _config;

  bool get _local => _config.deploymentMode == DeploymentMode.local;

  late final LocalizationManager localizationManager =
      (_local ? LocalResourceManager() : CarpResourceManager()) as LocalizationManager;

  late final LocalizationLoader localizationLoader = ResourceLocalizationLoader(localizationManager);

  late final MessageManager messageManager =
      (_local ? LocalResourceManager() : CarpResourceManager()) as MessageManager;

  late final InformedConsentManager informedConsentManager =
      (_local ? LocalResourceManager() : CarpResourceManager()) as InformedConsentManager;

  late final ParticipationService participationService = _local
      ? LocalParticipationService()
      : CarpParticipationService();
}
