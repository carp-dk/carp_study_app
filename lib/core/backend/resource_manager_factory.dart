part of carp_study_app;

/// The resource managers matching the current [DeploymentMode] - local assets
/// or CAWS-backed. Instances are created once and cached.
class ResourceManagerFactory {
  bool get _local => AppConfig.deploymentMode == DeploymentMode.local;

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
