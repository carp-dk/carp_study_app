part of carp_study_app;

class SurveyCard extends StatefulWidget {
  final TaskCardViewModel model;
  final List<Color> colors;

  const SurveyCard(this.model, {super.key, this.colors = CACHET.COLOR_LIST});

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  int get totalSurveys => widget.model.tasksTable.entries.length;

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    if (widget.model.tasksTable.isEmpty) {
      return const SizedBox();
    }

    return StudiesMaterial(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(locale.translate('cards.survey.title').toUpperCase(), style: Theme.of(context).textTheme.bodyLarge!.copyWith(letterSpacing: 1)),
            ),
            SizedBox(
              height: 160,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Row(
                children: [
                  // List of text with the number of surveys done for each survey
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.model.tasksTable.entries.map((entry) {
                          Widget dot = Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: widget.colors[widget.model.tasksTable.keys.toList().indexOf(entry.key)],
                              shape: BoxShape.circle,
                            ),
                          );
                          Widget text = Text(
                            '${entry.value} ${locale.translate(entry.key).truncateTo(12)}',
                            style: Theme.of(context).textTheme.bodySmall!,
                          );
                          return Row(children: [dot, const SizedBox(width: 8), text]);
                        }).toList(),
                      ),
                    ),
                  ),
                  // The pie chart
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(sections: pieChartSections, startDegreeOffset: 270)),
                        Text(
                          '$totalSurveys',
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.grey.shade800),
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

  List<PieChartSectionData> get pieChartSections {
    return widget.model.tasksTable.entries.map((entry) {
      return PieChartSectionData(
        // Color should be the next color in the list
        color: widget.colors[widget.model.tasksTable.keys.toList().indexOf(entry.key)],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        showTitle: false,
      );
    }).toList();
  }
}
