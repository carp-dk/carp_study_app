part of carp_study_app;

/// The details screen for a [Message] (announcement / news / article).
///
/// Pushed full-screen on the root navigator, in the design 2.0 card style.
class MessageDetailsPage extends StatelessWidget {
  static const String route = '/message';
  final String messageId;

  const MessageDetailsPage({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    final locale = RPLocalizations.of(context)!;
    final colors = Theme.of(context).extension<CarpColors>()!;
    final message = bloc.appViewModel.studyPageViewModel.messageById(messageId);
    final subTitle = message.subTitle ?? '';
    final body = message.message ?? '';
    final hasImage = message.image != null && message.image!.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: TextButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go(CarpAppState.homeRoute),
                icon: Icon(Icons.arrow_back_ios, size: 18, color: colors.primary),
                label: Text(
                  locale.translate('app_home.nav_bar_item.home'),
                  style: fs16fw600.copyWith(color: colors.primary),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  StudiesMaterial(
                    backgroundColor: colors.grey50!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage)
                          SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: bloc.appViewModel.studyPageViewModel.getMessageImage(message.image),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _typeChip(context, colors, message.type),
                              const SizedBox(height: 12),
                              Text(
                                locale.translate(message.title ?? ''),
                                style: fs20fw700.copyWith(color: colors.grey900),
                              ),
                              if (subTitle.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(locale.translate(subTitle), style: fs14fw600.copyWith(color: colors.grey600)),
                              ],
                              if (body.isNotEmpty) ...[
                                // The divider only earns its place when it has a
                                // subtitle to separate the body from.
                                if (subTitle.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Divider(height: 1, color: colors.grey200),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  locale.translate(body),
                                  style: fs16fw400.copyWith(color: colors.grey900, height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A pill with the message type's icon and label, in the accent colour.
  Widget _typeChip(BuildContext context, CarpColors colors, MessageType type) {
    final locale = RPLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              locale.translate(type.name.toLowerCase()),
              style: fs12fw600.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
