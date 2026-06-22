part of carp_study_app;

/// Tag prefixed to every app-specific log line. Filter device logs to just the
/// study app's own flow with `flutter logs | grep CARP_STUDY_APP` (these lines
/// are intentionally separate from the framework's `[CAMS ...]` logs).
const String appLogTag = 'CARP_STUDY_APP';

/// Log an app-specific [message] under the [appLogTag] tag.
///
/// Use for tracing the app's own flow (e.g. login → study) without dumping the
/// full state snapshot - reach for [logAppState] when the state matters.
void logApp(String message) => debugPrint('[$appLogTag] $message');

/// Log [message] followed by a one-line-per-field snapshot of the current app
/// state: bloc state, auth, backend, the active study/participant ids, consent,
/// and what is persisted in [LocalSettings].
///
/// Call this at the key transitions in the login → study flow to answer
/// "where am I and what do I have" at that exact point.
void logAppState(String message) => debugPrint('[$appLogTag] $message\n${_appStateSnapshot()}');

/// Evaluate [getter], returning a placeholder instead of throwing - state
/// logging must never crash the flow it is meant to observe.
Object? _safe(Object? Function() getter) {
  try {
    return getter();
  } catch (error) {
    return '<unavailable: $error>';
  }
}

/// A one-line-per-field dump of the current app state, used by [logAppState].
String _appStateSnapshot() {
  final buffer = StringBuffer();
  void line(String key, Object? value) => buffer.writeln('    $key = $value');

  SmartphoneStudy? study;
  try {
    study = bloc.study.study;
  } catch (_) {}
  final settings = LocalSettings();

  line('bloc.state', _safe(() => bloc.state.name));
  line('isInitialized/isConfiguring/isConfigured', _safe(() => '${bloc.isInitialized}/${bloc.isConfiguring}/${bloc.isConfigured}'));
  line('deploymentMode', _safe(() => AppConfig.deploymentMode.name));
  line('authenticated', _safe(() => bloc.auth.isAuthenticated));
  line('anonymous', _safe(() => bloc.auth.isAnonymous));
  line('user', _safe(() => bloc.auth.username));
  line('backend.study (seeded in CAWS)', _safe(() => CarpService().study?.studyDeploymentId));
  line('study.hasStudy', _safe(() => bloc.study.hasStudy));
  line('study.isDeployed', _safe(() => bloc.study.isDeployed));
  line('study.deploymentId', study?.studyDeploymentId);
  line('study.participantId', study?.participantId);
  line('study.participantRole', study?.participantRoleName);
  line('study.deviceRole', study?.deviceRoleName);
  line('consent.isAccepted', _safe(() => bloc.consent.isAccepted));
  line('LocalSettings.user', _safe(() => settings.user?.username));
  line('LocalSettings.study.deploymentId', _safe(() => settings.studyDeploymentId));
  line('LocalSettings.participant.id', _safe(() => settings.participant?.participantId));
  line('LocalSettings.participant.consentAccepted', _safe(() => settings.participant?.hasInformedConsentBeenAccepted));
  line('LocalSettings.isAnonymous', _safe(() => settings.isAnonymous));

  return buffer.toString().trimRight();
}
