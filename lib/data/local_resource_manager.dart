part of carp_study_app;

/// A local assets-based resource manager handling:
///  * informed consent
///  * localization
///  * messages
///  * study protocol
///
/// Local resource JSON files should be added to the app as assets in the
/// `assets/carp` folder following the normal structure from the "CARP Study App
/// Configurations" setup:
///
///  * protocol and consent files goes to 'carp/resources'
///  * language file goes to 'carp/lang'
///  * message files goes to 'carp/messages'
///
/// Note that the 'id' of the protocol in the [getStudyProtocol] method is ignored.
/// The 'protocol.json' file is always loaded.
class LocalResourceManager
    implements
        InformedConsentManager,
        LocalizationManager,
        MessageManager,
        StudyProtocolManager {
  /// The path to the json files to be loaded using this resource manager.
  static final String basePath = 'assets/carp';

  Map<String, String>? _translations;
  RPOrderedTask? _informedConsent;
  final Map<String, Message> _messages = {};
  SmartphoneStudyProtocol? _protocol;

  static final LocalResourceManager _instance = LocalResourceManager._();
  factory LocalResourceManager() => _instance;

  LocalResourceManager._() {
    ResearchPackage.ensureInitialized();
  }

  @override
  void initialize() {}

  // INFORMED CONSENT

  @override
  RPOrderedTask? get informedConsent => _informedConsent;

  @override
  Future<RPOrderedTask?> getInformedConsent({bool refresh = false}) async {
    if (_informedConsent == null) {
      try {
        var jsonString =
            await rootBundle.loadString('$basePath/resources/consent.json');
        Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;
        _informedConsent = RPOrderedTask.fromJson(jsonMap);
      } catch (error) {
        warning("$runtimeType - Could not load a local informed consent. "
            "It should be added as an asset resource in 'carp/resources/consent.json'. $error");
      }
    }
    return _informedConsent;
  }

  @override
  Future<bool> setInformedConsent(RPOrderedTask informedConsent) async {
    _informedConsent = informedConsent;
    return true;
  }

  @override
  Future<bool> deleteInformedConsent() async {
    _informedConsent = null;
    return true;
  }

  // LOCALIZATION

  @override
  Future<Map<String, String>> getLocalizations(
    Locale locale, {
    bool refresh = false,
  }) async {
    if (_translations == null) {
      var path = '$basePath/lang/${locale.languageCode}.json';
      var jsonString = await rootBundle.loadString(path);

      Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;
      _translations =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
    }
    return _translations!;
  }

  @override
  Future<bool> setLocalizations(
    Locale locale,
    Map<String, dynamic> localizations,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteLocalizations(Locale locale) {
    throw UnimplementedError();
  }

  @override
  bool isSupported(ui.Locale locale) => true;

  // MESSAGES

  @override
  Future<List<Message>> getMessages({
    DateTime? start,
    DateTime? end,
    int? count = 20,
  }) async {
    if (_messages.isEmpty) {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final files = assetManifest
          .listAssets()
          .where((string) => string.startsWith("$basePath/messages/"))
          .toList();

      for (var file in files) {
        var jsonString = await rootBundle.loadString(file);

        Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;

        var message = Message.fromJson(jsonMap);
        _messages[message.id] = message;
      }
    }
    return _messages.values
        .toList()
        .sublist(0, (count! < _messages.length) ? count : _messages.length);
  }

  @override
  Future<Message?> getMessage(String messageId) async => _messages[messageId];

  @override
  Future<void> setMessage(Message message) async =>
      _messages[message.id] = message;

  @override
  Future<void> deleteMessage(String messageId) async =>
      _messages.remove(messageId);

  @override
  Future<void> deleteAllMessages() async => _messages.clear();

  // PROTOCOL MANAGER

  @override
  Future<SmartphoneStudyProtocol?> getStudyProtocol(String id) async {
    if (_protocol == null) {
      try {
        var jsonString =
            await rootBundle.loadString('$basePath/resources/protocol.json');

        Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;
        _protocol = SmartphoneStudyProtocol.fromJson(jsonMap);

        if (_protocol?.dataEndPoint?.type != null) {
          if (!(_protocol!.dataEndPoint!.type == DataEndPointTypes.FILE ||
              _protocol!.dataEndPoint!.type == DataEndPointTypes.SQLITE)) {
            warning(
                "$runtimeType - Local protocol is trying to use a non-local data endpoint of type: '${_protocol!.dataEndPoint!.type}'. "
                "This will not work. Replacing this data endpoint to use a local SQLite backend instead. "
                "You can also change this in the local protocol stored in the 'carp/resources/protocol.json' file.");

            _protocol!.dataEndPoint = SQLiteDataEndPoint();
          }
        }
      } catch (error) {
        warning("$runtimeType - Could not load a local study protocol. "
            "It should be added as an asset resource in 'carp/resources/protocol.json'.\n"
            "Error: $error");
      }
    }
    return _protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String id, SmartphoneStudyProtocol protocol) {
    throw UnimplementedError();
  }
}
