part of carp_study_app;

/// How a message type is rendered - [IconData], so callers decide colour/size.
extension MessageTypeUI on MessageType {
  /// The icon representing this message type.
  IconData get icon => switch (this) {
    MessageType.announcement => Icons.campaign,
    MessageType.news => Icons.newspaper,
    MessageType.article => Icons.article,
  };
}
