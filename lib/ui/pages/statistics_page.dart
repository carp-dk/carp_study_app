part of carp_study_app;

class StatisticsPage extends StatefulWidget {
  static const String route = '/data';
  final StatisticsViewModel model;
  const StatisticsPage(this.model, {super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: CarpAppBar(hasProfileIcon: true),
            ),
            CarpPageTitle(locale.translate('pages.data_viz.title')),
            ..._sections(locale),
          ],
        ),
      ),
    );
  }

  /// The sections of the page, each only present when the study actually
  /// produces the data behind it - a measure in the protocol, tasks in the
  /// queue, or surveys the user has completed.
  List<Widget> _sections(RPLocalizations locale) {
    final model = widget.model;

    return [
      if (model.hasUserTasks) ...[
        TaskCompletionCard(model.studyProgressCardDataModel),
        CarpSectionTitle(locale.translate('cards.study_progress.title')),
        StudyProgressCardWidget(model.studyProgressCardDataModel),
      ],
      // A donut of a single survey type says nothing - it is one full ring.
      if (model.surveysCardDataModel.tasksTable.length >= 2) ...[
        CarpSectionTitle(locale.translate('cards.survey.title')),
        SurveyCard(model.surveysCardDataModel, showTitle: false),
      ],
      if (model.hasHeartRateMeasure) ...[
        CarpSectionTitle(locale.translate('cards.heartrate.title')),
        HeartRateCardWidget(model.heartRateCardDataModel),
      ],
      if (model.hasStepsMeasure) ...[
        CarpSectionTitle(locale.translate('cards.steps.title')),
        StepsCardWidget(model.stepsCardDataModel),
      ],
      if (model.hasActivityMeasure) ...[
        CarpSectionTitle(locale.translate('cards.activity.title')),
        ActivityCard(model.activityCardDataModel),
      ],
    ];
  }
}
