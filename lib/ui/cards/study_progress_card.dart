part of carp_study_app;

/// How the user's tasks are split across completed, pending, and expired - as
/// counts alongside a donut of the same three shares.
///
/// Tapping a slice highlights it and bolds the count it belongs to.
class StudyProgressCardWidget extends StatefulWidget {
  final StudyProgressCardViewModel model;
  final List<Color> colors;

  const StudyProgressCardWidget(
    this.model, {
    super.key,
    this.colors = const [Color(0xff2192C9), Color(0xffEB4B62), Color(0xffEC6330)],
  });

  @override
  State<StudyProgressCardWidget> createState() => _StudyProgressCardWidgetState();
}

class _StudyProgressCardWidgetState extends State<StudyProgressCardWidget> {
  /// The selected state, as an index into [StudyProgressCardViewModel.progress],
  /// or null when the card shows all three equally.
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return StudiesMaterial(
      backgroundColor: Theme.of(context).extension<CarpColors>()!.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selected = null),
        child: StreamBuilder(
          stream: widget.model.userTaskEvents,
          builder: (context, AsyncSnapshot<UserTask> snapshot) {
            widget.model.updateProgress();
            final progress = widget.model.progress;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [for (final (index, state) in progress.indexed) _count(context, index, state)],
                    ),
                  ),
                  SizedBox(width: 110, height: 110, child: _donut(progress)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _count(BuildContext context, int index, StudyProgress state) {
    final locale = RPLocalizations.of(context)!;
    final isSelected = _selected == index;

    return GestureDetector(
      onTap: () => setState(() => _selected = isSelected ? null : index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Pad to two digits so the labels line up in a column.
            Text(
              '${state.value}'.padLeft(2, '0'),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: _shade(widget.colors[index], index)),
            ),
            const SizedBox(width: 12),
            Text(
              locale.translate('cards.study_progress.${state.state}'),
              style: (isSelected ? Theme.of(context).textTheme.titleSmall! : Theme.of(context).textTheme.bodyLarge!),
            ),
          ],
        ),
      ),
    );
  }

  /// [color] at full strength when nothing is selected or this is it, washed
  /// out otherwise.
  Color _shade(Color color, int index) =>
      _selected == null || _selected == index ? color : color.withValues(alpha: 0.3);

  Widget _donut(List<StudyProgress> progress) {
    final total = progress.fold(0, (sum, state) => sum + state.value);
    // An empty study would render nothing at all - show the ring as untouched.
    if (total == 0) {
      return PieChart(
        PieChartData(
          centerSpaceRadius: 28,
          sections: [
            PieChartSectionData(color: const Color(0xff848484).withValues(alpha: 0.2), value: 1, showTitle: false, radius: 22),
          ],
        ),
      );
    }

    // Zero-value states get no slice, so the slice order is not the state
    // order - keep the state index on each slice to map a tap back.
    final slices = [
      for (final (index, state) in progress.indexed)
        if (state.value > 0) (index, state),
    ];

    return PieChart(
      PieChartData(
        centerSpaceRadius: 28,
        sectionsSpace: 2,
        startDegreeOffset: 270,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final slice = response?.touchedSection?.touchedSectionIndex;
            final selected = slice == null || slice < 0 ? null : slices[slice].$1;
            setState(() => _selected = selected == _selected ? null : selected);
          },
        ),
        sections: [
          for (final (index, state) in slices)
            PieChartSectionData(
              color: _shade(widget.colors[index], index),
              value: state.value.toDouble(),
              showTitle: false,
              // The selected slice also stands a little proud of the others.
              radius: _selected == index ? 26 : 22,
            ),
        ],
      ),
    );
  }
}
