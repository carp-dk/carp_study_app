part of carp_study_app;

class DistanceCard extends StatefulWidget {
  final MobilityCardViewModel model;
  final List<Color> colors;
  const DistanceCard(this.model, {super.key, this.colors = const [Color(0xff2192C9)]});

  @override
  State<DistanceCard> createState() => _DistanceCardState();
}

class _DistanceCardState extends State<DistanceCard> {
  /// The index (into [_days]) of the bar selected, or null for the week's average.
  int? _selectedIndex;

  /// The 7 days ending today, oldest first - today is always the last bar.
  List<DailyMobility> get _days => widget.model.days;

  /// The headline figure in km: the selected day, or the daily average.
  double get _distance => _selectedIndex != null
      ? _days[_selectedIndex!].distance
      : _days.fold<double>(0, (sum, day) => sum + day.distance) / _days.length;

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
                  Text(_distance.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineMedium!),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      _selectedIndex != null
                          ? '${locale.translate('cards.distance.distance')} ${weekdayName(context, _days[_selectedIndex!].date.weekday)}'
                          : '${locale.translate('cards.distance.distance')} - ${locale.translate('cards.distance.average')}',
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
                    "${widget.model.currentMonth} ${widget.model.startOfWeek} - ${int.parse(widget.model.endOfWeek) < int.parse(widget.model.startOfWeek) ? widget.model.nextMonth : widget.model.currentMonth} ${widget.model.endOfWeek}, ${widget.model.currentYear}",
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
                child: StreamBuilder(stream: widget.model.mobilityEvents, builder: (context, snapshot) => barCharts),
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
          // The distance above the chart already names the selected day.
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _selectedIndex = response?.spot?.touchedBarGroupIndex);
          },
        ),
        groupsSpace: 4,
        barGroups: [for (final (index, day) in _days.indexed) generateGroupData(index, day.distance)],
        maxY: max(_days.fold<double>(0, (m, day) => max(m, day.distance)) * 1.2, 1),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border.all(width: 1, color: Colors.grey.withValues(alpha: 0.2))),
      ),
    );
  }

  BarChartGroupData generateGroupData(int index, double distance) {
    // Nothing selected means the week as a whole - every bar reads the same.
    bool isTouched = _selectedIndex == null || _selectedIndex == index;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: distance,
          // Solid for the selected day, washed out for the rest.
          color: isTouched ? widget.colors[0] : widget.colors[0].withValues(alpha: 0.3),
          width: 32,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget rightTitles(double value, TitleMeta meta) => SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(
      value % meta.appliedInterval == 0 ? value.toStringAsFixed(1) : '',
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(letterSpacing: 1, color: Colors.grey.shade600),
    ),
  );

  Widget bottomTitles(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= _days.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(weekdayName(context, _days[index].date.weekday), style: const TextStyle(fontSize: 10)),
    );
  }
}
