/// Every route path in the app - pages and notification deep links link by these,
/// never by another feature's page class.
abstract final class Routes {
  /// Where the app lands once onboarding is done - redirects to [home].
  static const root = '/';
  static const login = '/login';
  static const codeSignIn = '/login/join';
  static const invitations = '/invitations';
  static const consent = '/consent';
  static const home = '/home';
  static const studyAbout = '/study_about';
  static const message = '/message';
  static const tasks = '/tasks';
  static const task = '/task';
  static const participantData = '/participant_data';
  static const statistics = '/data';
  static const connections = '/connections';
  static const profile = '/profile';
}
