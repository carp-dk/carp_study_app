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
  void initState() {
    super.initState();
    widget.model.refresh();
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        // Backfill lands in the card view models via addMeasurements(), which
        // notifies them directly - listen here so the page actually rebuilds
        // and re-reads the (now backfilled) card data.
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.model.stepsCardDataModel,
            widget.model.activityCardDataModel,
            widget.model.polarHeartRateCardDataModel,
            widget.model.movesenseHeartRateCardDataModel,
            widget.model.mobilityCardDataModel,
            widget.model.sleepCardDataModel,
          ]),
          builder: (context, _) => RefreshIndicator(
            onRefresh: widget.model.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
      // Every sensor card also needs data from the last 7 days - some probes
      // take a day or more to produce their first reading, and an all-empty
      // chart reads as broken rather than "not yet".
      if (model.hasPolarHeartRateMeasure && model.polarHeartRateCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.heartrate.polar.title')),
        HeartRateCardWidget(model.polarHeartRateCardDataModel),
      ],
      if (model.hasMovesenseHeartRateMeasure && model.movesenseHeartRateCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.heartrate.movesense.title')),
        HeartRateCardWidget(model.movesenseHeartRateCardDataModel),
      ],
      if (model.hasStepsMeasure && model.stepsCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.steps.title')),
        StepsCardWidget(model.stepsCardDataModel),
      ],
      if (model.hasActivityMeasure && model.activityCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.activity.title')),
        ActivityCard(model.activityCardDataModel),
      ],
      if (model.hasSleepMeasure && model.sleepCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.sleep.title')),
        SleepCardWidget(model.sleepCardDataModel),
      ],
      if (model.hasMobilityMeasure && model.mobilityCardDataModel.hasData) ...[
        CarpSectionTitle(locale.translate('cards.mobility.title')),
        MobilityCard(model.mobilityCardDataModel),
      ],
      if (model.hasMobilityMeasure && model.mobilityCardDataModel.hasDistanceData) ...[
        CarpSectionTitle(locale.translate('cards.distance.title')),
        DistanceCard(model.mobilityCardDataModel),
      ],
    ];
  }
}
