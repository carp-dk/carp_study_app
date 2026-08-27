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

  const SurveyCard(this.model, {super.key, this.colors = kChartColors, this.showTitle = true});

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
      backgroundColor: Colors.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selected = null),
        // Laid out to match [StudyProgressCardWidget] - same padding, same
        // donut, same type sizes - so the two cards read as a pair.
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    locale.translate('cards.survey.title').toUpperCase(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(letterSpacing: 1),
                  ),
                ),
              Row(
                children: [
                  Expanded(child: _legend(locale)),
                  SizedBox(width: 110, height: 110, child: _donut()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(RPLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, survey) in _surveys.indexed)
          GestureDetector(
            onTap: () => setState(() => _selected = _selected == index ? null : index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Pad to two digits so the labels line up in a column.
                  Text(
                    '${survey.value}'.padLeft(2, '0'),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall!.copyWith(color: _shade(widget.colors[index], index)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      locale.translate(survey.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (_selected == index
                          ? Theme.of(context).textTheme.titleSmall!
                          : Theme.of(context).textTheme.bodyLarge!),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _donut() {
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            centerSpaceRadius: 28,
            sectionsSpace: 2,
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
                  // The selected slice also stands a little proud of the others.
                  radius: _selected == index ? 26 : 22,
                ),
            ],
          ),
        ),
        Text('$_centreCount', style: Theme.of(context).textTheme.headlineSmall!),
      ],
    );
  }
}
