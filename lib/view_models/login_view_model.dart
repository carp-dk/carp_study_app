part of carp_study_app;

/// The outcome of a sign-in attempt.
enum SignInResult { success, offline, failed }

/// View model for [LoginPage] and [CodeSignInPage] - runs the sign-in flow
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

  /// Sign in anonymously using a scanned QR code.
  ///
  /// The QR code of a study invitation is a self-signup link
  /// (`https://<caws>/api/self-signup/<code>`), which is resolved to a magic
  /// link first. A magic link itself is also accepted.
  /// Returns false if [qrCode] is neither, without attempting to sign in.
  Future<bool> signInWithQrCode(String qrCode) async {
    final segments = Uri.tryParse(qrCode)?.pathSegments ?? [];
    final isSelfSignup = segments.length == 3 && segments[0] == 'api' && segments[1] == 'self-signup';
    return isSelfSignup ? signInWithCode(segments[2]) : signInWithMagicLink(qrCode);
  }

  /// Sign in anonymously using a magic link.
  /// Returns false if [link] is not a link, without attempting to sign in.
  Future<bool> signInWithMagicLink(String link) async {
    if (Uri.tryParse(link)?.hasAbsolutePath != true) return false;

    await _auth.authenticateWithMagicLink(link);

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
