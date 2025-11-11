part of carp_study_app;

class ScoreboardCard extends StatefulWidget {
  final TaskListPageViewModel model;
  const ScoreboardCard(this.model, {super.key});
  @override
  ScoreboardCardState createState() => ScoreboardCardState();
}

class ScoreboardCardState extends State<ScoreboardCard> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return SliverPersistentHeader(
      pinned: false,
      delegate: ScoreboardPersistentHeaderDelegate(
        model: widget.model,
        locale: locale,
        minExtent: 40,
        maxExtent: 110,
      ),
    );
  }
}

/// Make a [SliverPersistentHeaderDelegate] to use in a [SliverPersistentHeader] widget,
/// that can be used in a [CustomScrollView].
/// This is used in the [StudyPage] to make the header of the page.
/// The delegate should retract from 110px to 40px when scrolling down.
/// The animation should be simple and linear. A stretched header does not do anything.
class ScoreboardPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  TaskListPageViewModel model;
  RPLocalizations locale;
  @override
  final double minExtent;
  @override
  final double maxExtent;

  ScoreboardPersistentHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.model,
    required this.locale,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    double height = 110;

    double offsetForShrink = 50;

    List<Widget> childrenDays = [
      Text(model.daysInStudy.toString(),
          style: fs36fw800.copyWith(
              fontSize: calculateScrollAwareSizing(
                  shrinkOffset,
                  fs20fw800.fontSize!,
                  fs36fw800.fontSize!),
              color: Theme.of(context).extension<CarpColors>()!.grey900)),
      if (shrinkOffset < offsetForShrink)
        Text(locale.translate('cards.scoreboard.days'),
            style: fs12fw700.copyWith(
                color: Theme.of(context).extension<CarpColors>()!.grey900)),
      if (shrinkOffset > offsetForShrink)
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(locale.translate('cards.scoreboard.days-short'),
              style: fs12fw700.copyWith(
                  color: Theme.of(context).extension<CarpColors>()!.grey900)),
        )
    ];

    List<Widget> childrenTasks = [
      Text(model.taskCompleted.toString(),
          style: fs36fw800.copyWith(
              fontSize: calculateScrollAwareSizing(
                  shrinkOffset,
                  fs20fw800.fontSize!,
                  fs36fw800.fontSize!),
              color: Theme.of(context).extension<CarpColors>()!.primary)),
      if (shrinkOffset < offsetForShrink)
        Text(locale.translate('cards.scoreboard.tasks'),
            style: fs12fw700.copyWith(
                color: Theme.of(context).extension<CarpColors>()!.primary)),
      if (shrinkOffset > offsetForShrink)
        Expanded(
          flex: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(locale.translate('cards.scoreboard.tasks-short'),
                style: fs12fw700.copyWith(
                    color: Theme.of(context).extension<CarpColors>()!.primary)),
          ),
        )
    ];

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).extension<CarpColors>()!.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      child: StreamBuilder<UserTask>(
        stream: model.userTaskEvents,
        builder: (context, snapshot) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: shrinkOffset < offsetForShrink
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: childrenDays,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: childrenDays,
                      ),
              ),
              // A vertical divider line with rounded corners that spans from 10% to 90% of the height
              Expanded(
                flex: 0,
                child: Container(
                  height: calculateScrollAwareSizing(
                      shrinkOffset, minExtent * 0.6, maxExtent * 0.6),
                  width: 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Expanded(
                child: shrinkOffset < offsetForShrink
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: childrenTasks,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: childrenTasks,
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  // A simple function that returns the font size from the scoreNumberStyle, but increasingly smaller when scrolling down.
  // Also used for the size of the divider in the middle
  double calculateScrollAwareSizing(
      double shrinkOffset, double minSize, double maxSize) {
    // Calculate the normalized shrinkOffset value in the range [0, 1]
    double normalizedShrinkOffset = shrinkOffset / maxExtent;

    // Calculate the font size using linear interpolation
    double size = maxSize - normalizedShrinkOffset * (maxSize - minSize);

    // Return the calculated font size
    return size;
  }

  @override
  bool shouldRebuild(ScoreboardPersistentHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration =>
      FloatingHeaderSnapConfiguration(
        curve: Curves.linear,
        duration: const Duration(milliseconds: 100),
      );

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();
}
