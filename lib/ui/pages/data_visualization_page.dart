part of carp_study_app;

// todo change text for survey progress
class DataVisualizationPage extends StatefulWidget {
  static const String route = '/data';
  final DataVisualizationPageViewModel model;
  const DataVisualizationPage(this.model, {super.key});

  @override
  State<DataVisualizationPage> createState() => _DataVisualizationPageState();
}

class _DataVisualizationPageState extends State<DataVisualizationPage> {
  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
              child: const CarpAppBar(hasProfileIcon: true),
            ),
            Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate('pages.data_viz.title'),
                        style: fs24fw700.copyWith(
                          color: Theme.of(context).extension<CarpColors>()!.grey900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24.0),
                      child: Text(
                        locale.translate('pages.data_viz.thanks'),
                        style: fs16fw600.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600),
                      ),
                    ),
                    ..._dataVizCards,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The list of cards, depending on what measures are defined in the study.
  List<Widget> get _dataVizCards {
    final List<Widget> widgets = [];

    // Show user task progress, if study has any tasks.
    if (bloc.hasUserTasks()) {
      widgets.add(StudyProgressCardWidget(widget.model.studyProgressCardDataModel));
    }

    // Show HR if there is a POLAR or MOVESENSE device in the study
    if (bloc.hasMeasure(PolarSamplingPackage.HR) || bloc.hasMeasure(MovesenseSamplingPackage.HR)) {
      widgets.add(HeartRateOuterStatefulWidget(widget.model.heartRateCardDataModel));
    }

    // check to show surveys stats
    if (bloc.hasUserTasks()) {
      widgets.add(SurveyCard(widget.model.surveysCardDataModel));
    }

    List<TaskCardViewModel> mediaModelsList = [];

    // check what media types are in the study and add them to de media card
    if (bloc.hasMeasure(MediaSamplingPackage.AUDIO)) {
      mediaModelsList.add(widget.model.audioCardDataModel);
    }
    if (bloc.hasMeasure(MediaSamplingPackage.VIDEO)) {
      mediaModelsList.add(widget.model.videoCardDataModel);
    }
    if (bloc.hasMeasure(MediaSamplingPackage.IMAGE)) {
      mediaModelsList.add(widget.model.imageCardDataModel);
    }
    if (mediaModelsList.isNotEmpty) {
      widgets.add(MediaCardWidget(mediaModelsList));
    }

    if (bloc.hasMeasure(CarpDataTypes.STEP_COUNT)) {
      widgets.add(StepsCardWidget(widget.model.stepsCardDataModel));
    }
    if (bloc.hasMeasure(ContextSamplingPackage.ACTIVITY)) {
      widgets.add(ActivityCard(widget.model.activityCardDataModel));
    }
    if (bloc.hasMeasure(ContextSamplingPackage.MOBILITY)) {
      widgets.add(MobilityCard(widget.model.mobilityCardDataModel));
      widgets.add(DistanceCard(widget.model.mobilityCardDataModel));
    }

    return widgets.toSet().toList();
  }
}
