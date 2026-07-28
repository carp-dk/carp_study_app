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
  /// The bar the user tapped, or the last one - today - until they do.
  int _selected = StudyProgressCardViewModel.completionHistoryDays - 1;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CarpColors>()!;
    final locale = RPLocalizations.of(context)!;
    final completions = widget.model.recentCompletions;

    return StudiesMaterial(
      backgroundColor: colors.white!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(locale.translate('cards.task_completion.title'), style: fs16fw700),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event_note_outlined, color: colors.primary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _selectedDay(colors, locale, completions),
            const SizedBox(height: 8),
            SizedBox(height: 140, child: _chart(context, completions)),
          ],
        ),
      ),
    );
  }

  /// What the selected bar stands for, so the tap has somewhere to report to.
  Widget _selectedDay(CarpColors colors, RPLocalizations locale, List<int> completions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${completions[_selected]}', style: fs28fw700.copyWith(color: colors.grey900)),
        const SizedBox(width: 6),
        Text(
          locale.translate('cards.study_progress.completed').toLowerCase(),
          style: fs14fw600.copyWith(color: colors.grey600),
        ),
        const SizedBox(width: 8),
        Text('·', style: fs14fw600.copyWith(color: colors.grey500)),
        const SizedBox(width: 8),
        Text(DateFormat('dd/MM').format(_dateOf(_selected)), style: fs14fw600.copyWith(color: colors.grey600)),
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
            final index = response?.spot?.touchedBarGroupIndex;
            if (index != null && index != _selected) setState(() => _selected = index);
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: step.toDouble(),
          getDrawingHorizontalLine: (_) => FlLine(color: colors.grey300!, strokeWidth: 1),
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
                  // Solid for the selected day, washed out for the rest, so the
                  // selection reads at a glance.
                  color: index == _selected ? colors.primary : colors.primary!.withValues(alpha: 0.25),
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
    child: Text(text, style: fs12fw400.copyWith(color: Theme.of(context).extension<CarpColors>()!.grey600)),
  );
}
