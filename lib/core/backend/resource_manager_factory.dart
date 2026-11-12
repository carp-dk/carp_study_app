import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_study_app/core/backend/local_participation_service.dart';
import 'package:carp_study_app/core/backend/local_resource_manager.dart';
import 'package:carp_study_app/core/backend/localization_loader.dart';
import 'package:carp_study_app/core/util/app_config.dart';

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
