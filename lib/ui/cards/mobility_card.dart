part of carp_study_app;

/// Home stay per day as bars, with places visited and distance travelled -
/// the three features the mobility probe reports - below.
///
/// "Home" is not configured by the participant: the probe clusters the
/// phone's location into places and calls the one where most time is spent
/// between midnight and 06:00 home, recomputed each day. A day with no
/// night-time location at all has no home, and its bar is left empty rather
/// than drawn as 0%.
class MobilityCard extends StatefulWidget {
  final MobilityCardViewModel model;
  final List<Color> colors;
  const MobilityCard(this.model, {super.key, this.colors = const [Color(0xff7E9146), Color(0xff2192C9)]});

  @override
  State<MobilityCard> createState() => _MobilityCardState();
}

class _MobilityCardState extends State<MobilityCard> {
  /// The index (into [_days]) of the bar selected, or null for today.
  int? _selectedIndex;

  /// The 7 days ending today, oldest first - today is always the last bar.
  List<DailyMobility> get _days => widget.model.days;

  /// The day on show: the selected bar, or today when nothing is selected.
  DailyMobility get _day => _days[_selectedIndex ?? _days.length - 1];

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
                  Text(
                    _day.homeStay == null ? '-' : '${_day.homeStay}%',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: widget.colors[0]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      '${locale.translate('cards.mobility.homestay')} ${weekdayName(context, _day.date.weekday)}',
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _feature('${_day.places}', locale.translate('cards.mobility.places')),
                  _feature(_day.distance.toStringAsFixed(1), locale.translate('cards.mobility.distance')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(String value, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge!.copyWith(color: widget.colors[1])),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w700, color: Colors.grey.shade900),
      ),
    ],
  );

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
          // The figures above and below the chart already name the selected day.
          touchTooltipData: noBarTooltip,
          touchCallback: (event, response) {
            // Only settle on tap-up, so the selection is not dragged around -
            // and a tap on empty chart space clears it.
            if (event is! FlTapUpEvent) return;
            setState(() => _selectedIndex = response?.spot?.touchedBarGroupIndex);
          },
        ),
        groupsSpace: 4,
        barGroups: [for (final (index, day) in _days.indexed) generateGroupData(index, day.homeStay)],
        // Home stay is a percentage, so the axis is always the full 0-100.
        maxY: 100,
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

  BarChartGroupData generateGroupData(int index, int? homeStay) {
    // Nothing selected means today - which is a bar like any other.
    bool isTouched = _selectedIndex == null || _selectedIndex == index;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          // A day with no home found gets a full-width, zero-height rod, so
          // it keeps its slot on the x-axis instead of bunching the labels.
          toY: homeStay?.toDouble() ?? 0,
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
      value.toInt() % meta.appliedInterval == 0 ? '${value.toInt()}%' : '',
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
