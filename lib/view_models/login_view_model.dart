part of carp_study_app;

/// The outcome of a sign-in attempt.
enum SignInResult { success, offline, failed }

/// View model for [LoginPage] and [SignInDialog] - runs the sign-in flow
/// (CAWS web view, magic link, sign-in code) and sign-out.
class LoginViewModel extends ViewModel {
  /// The number of characters in a sign-in code.
  static const int codeLength = 5;

  /// Codes are letters and digits only, and always used upper-cased.
  static final RegExp codeFormat = RegExp('^[A-Z0-9]{$codeLength}\$');

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
    if (!await _system.checkConnectivity()) return SignInResult.offline;

    await _auth.initialize();
    await _auth.authenticate();

    notifyListeners();
    final result = _auth.isAuthenticated ? SignInResult.success : SignInResult.failed;
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

  /// Sign in anonymously using a [code] handed out with the study invitation.
  /// Returns false if [code] is malformed, without attempting to sign in.
  Future<bool> signInWithCode(String code) async {
    code = code.toUpperCase();
    if (!codeFormat.hasMatch(code)) return false;

    final link = await _auth.magicLinkForCode(code);
    return link != null && await signInWithMagicLink(link);
  }

  /// Sign out from CAWS, erasing all authentication information.
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
