part of carp_study_app;

class ActivityCard extends StatefulWidget {
  final ActivityCardViewModel model;
  final List<Color> colors;
  const ActivityCard(
    this.model, {
    super.key,
    this.colors = const [Color(0xff7E9146), Color(0xff228B89), Color(0xff82CEE9)],
  });

  @override
  State<StatefulWidget> createState() => ActivityCardState();
}

class ActivityCardState extends State<ActivityCard> {
  final betweenSpace = 2.4;

  /// The index (into [_days]) of the bar selected, or null for the week as a whole.
  int? _selectedIndex;

  /// The 7 days ending today, oldest first - today is always the last bar.
  List<DateTime> get _days => widget.model.days;

  /// The three activity types this card charts, bottom of the bar upwards.
  static const List<ActivityType> _types = ActivityCardViewModel.chartedTypes;

  /// Translation keys for [_types], in the same order.
  static const List<String> _legendKeys = ['walking', 'running', 'cycling'];

  /// Minutes of [type] on the day at [index] of [_days].
  num _minutesOn(ActivityType type, int index) => widget.model.minutesOn(type, _days[index]);

  /// Minutes of [type] on the selected day, or across the window when none is.
  num _minutes(ActivityType type) => _selectedIndex != null
      ? _minutesOn(type, _selectedIndex!)
      : List.generate(7, (index) => _minutesOn(type, index)).fold<num>(0, (sum, minutes) => sum + minutes);

  /// Minutes across all charted activities, for the selected day or the week.
  num get _total => _types.fold<num>(0, (sum, type) => sum + _minutes(type));

  /// The tallest stacked bar, so the axis has somewhere to end.
  num get _maxValue =>
      List.generate(7, (index) => _types.fold<num>(0, (sum, type) => sum + _minutesOn(type, index))).fold<num>(0, max);

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
                children: [
                  Text('$_total', style: Theme.of(context).textTheme.headlineMedium!),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '${locale.translate('cards.activity.total.min')} ${_selectedIndex != null ? weekdayName(context, _days[_selectedIndex!].weekday) : ''}',
                      style: Theme.of(context).textTheme.labelSmall!
                          .copyWith(fontWeight: FontWeight.w700)
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    weekRangeLabel(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700).copyWith(color: Colors.grey.shade600),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(
                height: 160,
                width: MediaQuery.of(context).size.width * 0.9,
                child: StreamBuilder(
                  stream: widget.model.activityEvents,
                  builder: (context, snapshot) {
                    return barCharts;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Wraps to as many lines as it needs, so the legend keeps its
              // spacing instead of the entries closing up on a narrow screen.
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  for (final (index, type) in _types.indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_minutes(type)}',
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[index]),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locale.translate('cards.activity.${_legendKeys[index]}'),
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
            sideTitles: SideTitles(showTitles: true, getTitlesWidget: rightTitles, reservedSize: 48),
          ),
          topTitles: const AxisTitles(),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          // The totals above and below the chart already name the selected day.
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _selectedIndex = response?.spot?.touchedBarGroupIndex);
          },
        ),
        groupsSpace: 4,
        barGroups: [
          for (int index = 0; index < 7; index++)
            generateGroupData(index, [for (final type in _types) _minutesOn(type, index)]),
        ],
        maxY: _maxValue * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: true, border: Border.all(width: 1, color: Colors.grey.withValues(alpha: 0.2))),
      ),
    );
  }

  BarChartGroupData generateGroupData(int x, List<num> minutes) {
    const roundness = Radius.circular(2);
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedIndex == null || _selectedIndex == x;
    // Solid for the selected day, washed out for the rest.
    Color shade(Color color) => isTouched ? color : color.withValues(alpha: 0.3);

    final segments = stackSegments(minutes, betweenSpace);

    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        // A day with nothing to show still needs a full-width rod, or the
        // group collapses and spaceAround bunches up its weekday label.
        if (segments.isEmpty) BarChartRodData(toY: 0, width: 32),
        for (final (position, (index, from, to)) in segments.indexed)
          BarChartRodData(
            fromY: from,
            toY: to,
            color: shade(widget.colors[index]),
            width: 32,
            // Only the topmost segment gets the rounded cap.
            borderRadius: position == segments.length - 1
                ? const BorderRadius.vertical(top: Radius.circular(4), bottom: roundness)
                : const BorderRadius.all(roundness),
          ),
      ],
    );
  }

  Widget rightTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(
        value.toInt() % meta.appliedInterval == 0 ? value.toInt().toString() : '',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(letterSpacing: 1).copyWith(color: Colors.grey.shade600),
      ),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= _days.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(weekdayName(context, _days[index].weekday), style: const TextStyle(fontSize: 10)),
    );
  }
}
