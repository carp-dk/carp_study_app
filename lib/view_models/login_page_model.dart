part of carp_study_app;

/// The outcome of a sign-in attempt.
enum SignInResult { success, offline, failed }

/// The view model for the [LoginPage] and [QRViewExample] - owns the
/// authentication flow.
class LoginViewModel extends ViewModel {
  LoginViewModel({AuthService? authService, SystemInfoService? systemInfoService})
    : _authService = authService,
      _systemInfoService = systemInfoService;

  final AuthService? _authService;
  final SystemInfoService? _systemInfoService;
  AuthService get _auth => _authService ?? bloc.auth;
  SystemInfoService get _system => _systemInfoService ?? bloc.system;

  /// Has the user been authenticated?
  bool get isAuthenticated => _auth.isAuthenticated;

  /// Sign in via the CAWS web view.
  Future<SignInResult> signIn() async {
    logAppState('LoginViewModel.signIn() START');
    if (!await _system.checkConnectivity()) return SignInResult.offline;

    await _auth.initialize();
    await _auth.authenticate();

    notifyListeners();
    final result = _auth.isAuthenticated ? SignInResult.success : SignInResult.failed;
    logAppState('LoginViewModel.signIn() DONE - result=${result.name}');
    return result;
  }

  /// Sign in anonymously using a scanned magic link.
  /// Returns false if [qrCode] is not a link, without attempting to sign in.
  Future<bool> signInWithMagicLink(String qrCode) async {
    if (Uri.tryParse(qrCode)?.hasAbsolutePath != true) return false;

    await _auth.authenticateWithMagicLink(qrCode);

    notifyListeners();
    return _auth.isAuthenticated;
  }

  /// Sign out from CAWS, erasing all authentication information.
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
