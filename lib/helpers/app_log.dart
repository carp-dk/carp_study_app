part of carp_study_app;

/// Tag prefixed to every app-specific log line - filter with
/// `flutter logs | grep CARP_STUDY_APP`.
const String appLogTag = 'CARP_STUDY_APP';

/// Log an app-specific [message] under the [appLogTag] tag.
void logApp(String message) => debugPrint('[$appLogTag] $message');
