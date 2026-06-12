part of carp_study_app;

/// Holds the list of messages (news, announcements, articles) shown in the
/// app and keeps it refreshed, owning the periodic polling timer.
class MessageService {
  MessageService(this._manager, {Duration pollingInterval = const Duration(minutes: 30)})
    : _pollingInterval = pollingInterval;

  final MessageManager _manager;
  final Duration _pollingInterval;
  final StreamController<int> _streamController = StreamController.broadcast();
  List<Message> _messages = [];
  Timer? _pollingTimer;

  /// The list of currently available messages, newest first.
  List<Message> get messages => _messages;

  /// A stream of events when the list of [messages] is updated.
  /// The data sent on the stream is the number of available messages.
  Stream<int> get stream => _streamController.stream;

  /// The message with the given [id], or null if not found.
  Message? byId(String id) => _messages.where((message) => message.id == id).firstOrNull;

  /// Initialize the message manager, fetch messages, and start polling for
  /// new messages on a regular basis. Safe to call more than once.
  void start() {
    _manager.initialize();
    refresh();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) => refresh());
  }

  /// Stop polling for new messages.
  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh the list of messages.
  Future<void> refresh() async {
    try {
      _messages = await _manager.getMessages();
      _messages.sort((m1, m2) => m2.timestamp.compareTo(m1.timestamp));
      info('Message list refreshed - count: ${_messages.length}');
    } catch (error) {
      warning('Error getting messages - $error');
    }
    if (!_streamController.isClosed) _streamController.add(_messages.length);
  }

  void dispose() {
    stop();
    _streamController.close();
  }
}
