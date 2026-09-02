part of carp_study_app;

/// Hours asleep per night, stacked by sleep stage, with per-stage totals as
/// a legend below. An unstaged night is drawn as a single "asleep" segment.
class SleepCardWidget extends StatefulWidget {
  final SleepCardViewModel model;

  /// One colour per [SleepCardViewModel.sleepStageTypes], deepest first.
  final List<Color> colors;
  const SleepCardWidget(
    this.model, {
    super.key,
    // Shades of purple, darker = deeper sleep: deep, light, REM. "Asleep"
    // breaks the fade and goes back to a dark shade - it draws whole
    // unstaged nights on its own, and a pale bar cannot read as selected
    // next to washed-out staged bars.
    this.colors = const [Color(0xff3B2E6E), Color(0xff6D5BAF), Color(0xffB3A6E0), Color(0xff5B4B9B)],
  });

  @override
  State<SleepCardWidget> createState() => _SleepCardWidgetState();
}

class _SleepCardWidgetState extends State<SleepCardWidget> {
  /// The index (into [_nights]) of the bar selected, or null for the average.
  int? _selectedIndex;

  /// The gap between stacked stages, in hours - small enough not to read as
  /// sleep, big enough to tell the segments apart.
  static const double betweenSpace = 0.08;

  /// Translation keys for the segments of a night, in the order
  /// [WeeklySleep.segmentsOn] returns them.
  static const List<String> _legendKeys = ['deep', 'light', 'rem', 'asleep'];

  /// The 7 nights ending today, oldest first - today is always the last bar.
  List<DailySleep> get _nights => widget.model.nights;

  /// Hours of each segment of the night at [index] - the three stages, then
  /// whatever unstaged sleep stands in for them on a night without stages.
  List<double> _stageHours(int index) =>
      widget.model.model.segmentsOn(_nights[index].date).map((minutes) => minutes / 60).toList();

  /// Hours of the segment at [stageIndex] on the selected night, or summed
  /// across the window when no night is selected.
  double _stage(int stageIndex) => _selectedIndex != null
      ? _stageHours(_selectedIndex!)[stageIndex]
      : List.generate(_nights.length, (i) => _stageHours(i)[stageIndex]).fold<double>(0, (sum, hours) => sum + hours);

  /// The headline figure in hours: the selected night, or the average over
  /// the nights that actually have sleep recorded.
  double get _hours {
    if (_selectedIndex != null) return _nights[_selectedIndex!].hours;
    final recorded = _nights.where((night) => night.minutes > 0);
    if (recorded.isEmpty) return 0;
    return recorded.fold<double>(0, (sum, night) => sum + night.hours) / recorded.length;
  }

  /// Hours and minutes, e.g. "7h 20m" - a night is never read as "7.33".
  /// Rounded as one figure, so 7.999 h reads "8h 0m" and never "7h 60m".
  String _duration(double hours) {
    final minutes = (hours * 60).round();
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    RPLocalizations locale = RPLocalizations.of(context)!;

    return StudiesMaterial(
      backgroundColor: Colors.white,
      // Tapping anywhere else on the card drops the selection.
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = null),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_duration(_hours), style: Theme.of(context).textTheme.headlineMedium!),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      _selectedIndex != null
                          ? '${locale.translate('cards.sleep.asleep')} ${weekdayName(context, _nights[_selectedIndex!].date.weekday)}'
                          : locale.translate('cards.sleep.average'),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              Row(
                children: [
                  Text(
                    weekRangeLabel(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(
                height: 160,
                width: MediaQuery.of(context).size.width * 0.9,
                child: StreamBuilder(stream: widget.model.sleepEvents, builder: (context, snapshot) => barCharts),
              ),
              const SizedBox(height: 16),
              // Wraps to as many lines as it needs, so the legend keeps its
              // spacing instead of the entries closing up on a narrow screen.
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  for (var stage = 0; stage < _legendKeys.length; stage++)
                    // Only name the stages this phone actually reports - an
                    // iPhone without a watch has "asleep" and nothing else.
                    if (_stage(stage) > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _duration(_stage(stage)),
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[stage]),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locale.translate('cards.sleep.${_legendKeys[stage]}'),
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                          ),
                        ],
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChart get barCharts {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: bottomTitles, reservedSize: 24),
          ),
          leftTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: rightTitles, reservedSize: 48, interval: 2),
          ),
          topTitles: const AxisTitles(),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          // The duration above the chart already names the selected night.
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _selectedIndex = response?.spot?.touchedBarGroupIndex);
          },
        ),
        groupsSpace: 4,
        barGroups: [for (var index = 0; index < _nights.length; index++) generateGroupData(index, _stageHours(index))],
        // At least a 10 h axis, so a normal night is not drawn full-height.
        // Measured off the stacked segments, gaps included, so the tallest
        // bar cannot overshoot the top of the chart.
        maxY: max(
          List.generate(
                _nights.length,
                (index) => stackSegments(_stageHours(index), betweenSpace).lastOrNull?.$3 ?? 0,
              ).fold<double>(0, max) *
              1.1,
          10,
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 2,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border.all(width: 1, color: Colors.grey.withValues(alpha: 0.2))),
      ),
    );
  }

  BarChartGroupData generateGroupData(int index, List<double> stageHours) {
    const roundness = Radius.circular(2);
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedIndex == null || _selectedIndex == index;
    // Solid for the selected night, washed out for the rest. Washed further
    // than the other cards (0.15 vs 0.3): the palette's lightest stage at
    // full opacity must still read stronger than the darkest stage washed
    // out, or the selected bar looks LESS highlighted than its neighbours.
    Color shade(Color color) => isTouched ? color : color.withValues(alpha: 0.15);

    final segments = stackSegments(stageHours, betweenSpace);

    return BarChartGroupData(
      x: index,
      groupVertically: true,
      barRods: [
        // A night with nothing recorded still needs a full-width rod, or the
        // group collapses and spaceAround bunches up its weekday label.
        if (segments.isEmpty) BarChartRodData(toY: 0, width: 32),
        for (final (position, (stage, from, to)) in segments.indexed)
          BarChartRodData(
            fromY: from,
            toY: to,
            color: shade(widget.colors[stage]),
            width: 32,
            // Only the topmost segment gets the rounded cap.
            borderRadius: position == segments.length - 1
                ? const BorderRadius.vertical(top: Radius.circular(4), bottom: roundness)
                : const BorderRadius.all(roundness),
          ),
      ],
    );
  }

  Widget rightTitles(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(
      '${value.toInt()}h',
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(letterSpacing: 1, color: Colors.grey.shade600),
    ),
  );

  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= _nights.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(weekdayName(context, _nights[index].date.weekday), style: const TextStyle(fontSize: 10)),
    );
  }
}
