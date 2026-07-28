part of carp_study_app;

/// How many surveys of each type the user has completed, as a donut with the
/// total in the middle.
///
/// Tapping a slice highlights it, bolds its legend entry, and swaps the middle
/// number for that type's count.
class SurveyCard extends StatefulWidget {
  final TaskCardViewModel model;
  final List<Color> colors;

  /// Show the card's own "SURVEYS" header. Off when a page section title
  /// already labels the card (e.g. the home page).
  final bool showTitle;

  const SurveyCard(this.model, {super.key, this.colors = CACHET.COLOR_LIST, this.showTitle = true});

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  /// The selected survey type, or null for every type at once.
  int? _selected;

  List<MapEntry<String, int>> get _surveys => widget.model.tasksTable.entries.toList();

  /// The number in the middle: the selected type, or every completed survey.
  int get _centreCount => _selected != null ? _surveys[_selected!].value : widget.model.tasksDone;

  /// [color] at full strength when nothing is selected or this is it, washed
  /// out otherwise.
  Color _shade(Color color, int index) =>
      _selected == null || _selected == index ? color : color.withValues(alpha: 0.3);

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;
    if (_surveys.isEmpty) return const SizedBox();

    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white!,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selected = null),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(locale.translate('cards.survey.title').toUpperCase(), style: fs16fw400ls1),
                ),
              SizedBox(
                height: 160,
                width: MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _legend(locale)),
                    Expanded(flex: 3, child: _donut()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(RPLocalizations locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (index, survey) in _surveys.indexed)
            GestureDetector(
              onTap: () => setState(() => _selected = _selected == index ? null : index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _shade(widget.colors[index], index), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${survey.value} ${locale.translate(survey.key).truncateTo(12)}',
                      style: _selected == index ? fs12fw700 : fs12fw400,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _donut() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: 270,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (event is! FlTapUpEvent) return;
                final slice = response?.touchedSection?.touchedSectionIndex;
                final selected = slice == null || slice < 0 ? null : slice;
                setState(() => _selected = selected == _selected ? null : selected);
              },
            ),
            sections: [
              for (final (index, survey) in _surveys.indexed)
                PieChartSectionData(
                  color: _shade(widget.colors[index], index),
                  value: survey.value.toDouble(),
                  showTitle: false,
                ),
            ],
          ),
        ),
        Text('$_centreCount', style: fs24fw700.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey800)),
      ],
    );
  }
}
