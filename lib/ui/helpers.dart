part of carp_study_app;

/// UI presentation helpers for [MessageType].
///
/// Single source of truth for how a message type is rendered. Returns
/// [IconData] (not a widget) so callers decide colour and size.
extension MessageTypeUI on MessageType {
  /// The icon representing this message type.
  IconData get icon => switch (this) {
        MessageType.announcement => Icons.campaign,
        MessageType.news => Icons.newspaper,
        MessageType.article => Icons.article,
      };
}
