part of carp_study_app;

/// Tag prefixed to every app-specific log line. Filter device logs to just the
/// study app's own flow with `flutter logs | grep CARP_STUDY_APP` (these lines
/// are intentionally separate from the framework's `[CAMS ...]` logs).
const String appLogTag = 'CARP_STUDY_APP';

/// Log an app-specific [message] under the [appLogTag] tag.
///
/// Use for tracing the app's own flow, e.g. login → study.
void logApp(String message) => debugPrint('[$appLogTag] $message');
