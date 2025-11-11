part of carp_study_app;

class AnonymousCard extends StatelessWidget {
  const AnonymousCard({super.key});

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return Card(
      color: Theme.of(context).extension<RPColors>()!.grey50,
      elevation: 0,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 22.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 4),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: CACHET.ANONYMOUS,
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            locale.translate('pages.about.anonymous.anonymous'),
                            maxLines: 2,
                            style: aboutCardSubtitleStyle.copyWith(
                                color: CACHET.ANONYMOUS),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          locale.translate('pages.about.anonymous.message'),
                          style: aboutCardSubtitleStyle.copyWith(
                            color: Theme.of(context)
                                .extension<RPColors>()!
                                .grey900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
