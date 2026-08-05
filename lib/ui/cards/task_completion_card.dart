part of carp_study_app;

/// How many tasks the user completed on each of the last two weeks' days, as a
/// bar per day. Tapping a bar selects it and reports that day above the chart.
class TaskCompletionCard extends StatefulWidget {
  final StudyProgressCardViewModel model;
  const TaskCompletionCard(this.model, {super.key});

  @override
  State<TaskCompletionCard> createState() => _TaskCompletionCardState();
}

class _TaskCompletionCardState extends State<TaskCompletionCard> {
  /// The bar the user tapped, or null for the whole fortnight.
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;
    final completions = widget.model.recentCompletions;
    final selected = _selected;

    return StudiesMaterial(
      backgroundColor: colors.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selected = null),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? locale.translate('cards.task_completion.title')
                          : '${locale.translate('cards.task_completion.title_on')} '
                                '${DateFormat('dd/MM').format(_dateOf(selected))}',
                      style: Theme.of(context).textTheme.titleSmall!,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.event_note_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _headline(colors, locale, completions),
              const SizedBox(height: 8),
              SizedBox(height: 140, child: _chart(context, completions)),
            ],
          ),
        ),
      ),
    );
  }

  /// The count the title refers to: the selected day, or the fortnight total.
  Widget _headline(CarpColors colors, RPLocalizations locale, List<int> completions) {
    final count = _selected != null ? completions[_selected!] : completions.fold(0, (sum, day) => sum + day);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$count', style: Theme.of(context).textTheme.headlineMedium!),
        const SizedBox(width: 6),
        Text(
          locale.translate('pages.task_list.title').toLowerCase(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colors.grey600),
        ),
      ],
    );
  }

  /// The day the bar at [index] covers, counting back from today.
  DateTime _dateOf(int index) =>
      DateTime.now().subtract(Duration(days: StudyProgressCardViewModel.completionHistoryDays - 1 - index));

  Widget _chart(BuildContext context, List<int> completions) {
    final colors = Theme.of(context).extension<CarpColors>()!;
    final busiest = completions.fold(0, max);
    // Whole-number gridlines - a fractional interval renders as repeated
    // labels ("1 1 0 0") once the busiest day is only a task or two.
    final step = busiest <= 4 ? 1 : (busiest / 4).ceil();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (step * 4).toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          // The header above the chart reports the selection - a tooltip on top
          // of it would say the same thing twice.
          touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => Colors.transparent),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            // Tapping the selected bar - or the empty space around them - clears
            // the selection and puts the fortnight total back.
            final index = response?.spot?.touchedBarGroupIndex;
            setState(() => _selected = index == _selected ? null : index);
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step.toDouble(),
          getDrawingHorizontalLine: (_) => FlLine(color: colors.grey300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: step.toDouble(),
              getTitlesWidget: (value, meta) => _axisLabel(context, meta, '${value.toInt()}'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) => _axisLabel(context, meta, '${value.toInt() + 1}'),
            ),
          ),
        ),
        barGroups: [
          for (final (index, completed) in completions.indexed)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: completed.toDouble(),
                  // Nothing selected means the fortnight as a whole - every bar
                  // reads the same. Otherwise only the selected one is solid.
                  color: _selected == null || index == _selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _axisLabel(BuildContext context, TitleMeta meta, String text) => SideTitleWidget(
    meta: meta,
    child: Text(text, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600)),
  );
}
