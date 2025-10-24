part of carp_study_app;

class MessageDetailsPage extends StatelessWidget {
  static const String route = '/message';
  final String messageId;

  const MessageDetailsPage({
    super.key,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    Message message = bloc.messages
        .firstWhere((element) => element.id == messageId, orElse: () {
      return Message(
          id: '0',
          title: 'Unknown message',
          subTitle: 'Unknown message',
          type: MessageType.announcement,
          timestamp: DateTime.now(),
          image: './assets/images/kids.png');
    });

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.secondary,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 18),
                child: const CarpAppBar(hasProfileIcon: true),
              ),
              Row(
                children: [
                  IconButton(
                    padding: const EdgeInsets.only(
                        left: 26, right: 10, top: 16, bottom: 16),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).extension<RPColors>()!.grey600,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(CarpStudyAppState.homeRoute);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(locale.translate(message.title!),
                        style: aboutCardTitleStyle.copyWith(
                            color: Theme.of(context)
                                .extension<RPColors>()!
                                .grey900)),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Material(
                      color: CACHET.DEPLOYMENT_DEPLOYING,
                      borderRadius: BorderRadius.circular(100.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        child: Text(
                            locale.translate(message.type
                                .toString()
                                .split('.')
                                .last
                                .toLowerCase()),
                            style: aboutCardSubtitleStyle.copyWith(
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    message.subTitle != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 6.0),
                            child: Text(locale.translate(message.subTitle!),
                                style: aboutCardContentStyle.copyWith(
                                    color: Theme.of(context)
                                        .extension<RPColors>()!
                                        .grey700)),
                          )
                        : const SizedBox.shrink(),
                    if (message.image != null && message.image!.isNotEmpty)
                      LayoutBuilder(builder: (context, constraints) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.height;
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenHeight,
                            maxHeight: screenWidth,
                          ),
                          child: FittedBox(
                              fit: BoxFit.contain,
                              child: bloc.appViewModel.studyPageViewModel
                                  .getMessageImage(message.image)),
                        );
                      }),
                    // DetailsBanner(message.title ?? '', message.image),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.message != null)
                            Text(
                              locale.translate(message.message!),
                              style: aboutCardContentStyle.copyWith(
                                  color: Theme.of(context)
                                      .extension<RPColors>()!
                                      .grey900),
                              textAlign: TextAlign.justify,
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
